module PortGraph.ForceExtra exposing
    ( Entity, entity, simulation, State, isCompleted, reheat, iterations, computeSimulation, tick
    , Force, center, links, customLinks, manyBody, manyBodyStrength, customManyBody, collision, customCollision
    , towardsX, towardsY, customRadial
    , getPortCoordinate, updateDistanceStrengthsInState, updatePortDict, updatePortDistance
    )

{-| This module implements a velocity Verlet numerical integrator for simulating physical forces on particles.
The simulation is simplified: it assumes a constant unit time step _Δt = 1_ for each step, and a constant unit
mass _m = 1_ for all particles. As a result, a force _F_ acting on a particle is equivalent to a constant
acceleration _a_ over the time interval _Δt_, and can be simulated simply by adding to the particle’s velocity,
which is then added to the particle’s position.

[![force directed graph illustration](https://elm-visualization.netlify.com/ForceDirectedGraph/preview@2x.png)](https://elm-visualization.netlify.com/ForceDirectedGraph/)

In the domain of information visualization, physical simulations are useful for studying networks and hierarchies!


## Additional Information

ForceExtra/ ディレクトリ以下のコードは，
elm-visualization の Force/ ディレクトリ以下のコードをそのまま使っているだけ．

ForceExtra.elm のみ変更を加えている．


## Simulation

@docs Entity, entity, simulation, State, isCompleted, reheat, iterations, computeSimulation, tick


## Forces

@docs Force, center, links, customLinks, manyBody, manyBodyStrength, customManyBody, collision, customCollision

The x- and y-positioning forces push nodes towards a desired position along the given dimension with a configurable strength. The strength of the force is proportional to the one-dimensional distance between the node’s position and the target position.

@docs towardsX, towardsY, customRadial

-}

import Dict exposing (Dict)
import ForceExtra.Collision as Collision
import ForceExtra.ManyBody as ManyBody
import IntDict exposing (IntDict)
import PortGraph.PortGraph as PortGraph exposing (ConnectedTo(..), Graph, PortDict, extractNodeId)



-- Force


{-| Force needs to compute and update positions and velocities on any objects that it is simulating.
However, you can use your own data structure to manage these, as long as the individual objects expose the necessary
properties. Therefore this type alias is an extensible record allowing you to avoid excessive nesting.

The `id` property must be unique among objects, otherwise some of the colliding objects will be ignored by the simulation.

Also take care when initializing the positions so that the points don't overlap.

-}
type alias Entity comparable a =
    { a
        | x : Float
        , y : Float
        , vx : Float
        , vy : Float
        , id : comparable
    }


initialRadius : Float
initialRadius =
    10


initialAngle : Float
initialAngle =
    pi * (3 - sqrt 5)


{-| This will run the entire simulation until it is completed and then returns the entities. Essentially keeps calling
`tick` until the simulation is done.

Note that this is fairly computationally expensive and may freeze the UI for a while if the dataset is large.

-}
computeSimulation : State comparable -> List (Entity comparable a) -> List (Entity comparable a)
computeSimulation state entities =
    if isCompleted state then
        entities

    else
        let
            ( newState, newEntities ) =
                tick state entities
        in
        computeSimulation newState newEntities


{-| This is a convenience function for wrapping data up as Entities. The initial position of entities is arranged
in a [phylotaxic pattern](https://elm-visualization.netlify.com/Petals/). Goes well with `List.indexedMap`.
-}
entity : Int -> a -> Entity Int { value : a }
entity index a =
    let
        radius =
            sqrt (0.5 + toFloat index) * initialRadius

        angle =
            toFloat index * initialAngle
    in
    { x = radius * cos angle
    , y = radius * sin angle
    , vx = 0.0
    , vy = 0.0
    , id = index
    , value = a
    }


{-| `getPortCoordinate 0 portDistance portDict connectedTo ent`
-}
getPortCoordinate : Float -> Float -> PortDict comparable -> ConnectedTo comparable -> ( Float, Float ) -> ( Float, Float )
getPortCoordinate additionalDegree portDistance portDict connectedTo ( x, y ) =
    case connectedTo of
        HL nodeId ->
            ( x, y )

        Port ( nodeId, portId ) ->
            case PortGraph.getPort portDict nodeId portId of
                Nothing ->
                    ( x, y )

                Just port_ ->
                    let
                        ( px, py ) =
                            fromPolar ( portDistance, degrees <| port_.angle + additionalDegree )
                    in
                    ( x + px, y + py )


applyForce : Float -> Force comparable -> Dict comparable (Entity comparable a) -> Dict comparable (Entity comparable a)
applyForce alpha force entities =
    case force of
        Center x y ->
            let
                ( sumx, sumy ) =
                    Dict.foldr (\_ ent ( sx0, sy0 ) -> ( sx0 + ent.x, sy0 + ent.y )) ( 0, 0 ) entities

                n =
                    toFloat <| Dict.size entities

                sx =
                    sumx / n - x

                sy =
                    sumy / n - y
            in
            Dict.map (\_ ent -> { ent | x = ent.x - sx, y = ent.y - sy }) entities

        Collision iters strength radii ->
            Collision.wrapper strength iters radii entities

        Links iters portDistance portDict lnks ->
            nTimes
                (\entitiesList ->
                    List.foldl
                        (\{ source, target, distance, strength, bias } ents ->
                            case ( Dict.get (extractNodeId source) ents, Dict.get (extractNodeId target) ents ) of
                                ( Just sourceNode, Just targetNode ) ->
                                    let
                                        ( sx, sy ) =
                                            getPortCoordinate 0 portDistance portDict source ( sourceNode.x, sourceNode.y )

                                        ( tx, ty ) =
                                            getPortCoordinate 0 portDistance portDict target ( targetNode.x, targetNode.y )

                                        x =
                                            tx + targetNode.vx - sx - sourceNode.vx

                                        y =
                                            ty + targetNode.vy - sy - sourceNode.vy

                                        d =
                                            sqrt (x ^ 2 + y ^ 2)

                                        l =
                                            (d - distance) / d * alpha * strength
                                    in
                                    ents
                                        |> Dict.update (extractNodeId target) (Maybe.map (\sn -> { sn | vx = sn.vx - x * l * bias, vy = sn.vy - y * l * bias }))
                                        |> Dict.update (extractNodeId source) (Maybe.map (\tn -> { tn | vx = tn.vx + x * l * (1 - bias), vy = tn.vy + y * l * (1 - bias) }))

                                otherwise ->
                                    ents
                        )
                        entitiesList
                        lnks
                )
                iters
                entities

        ManyBody theta entityStrengths ->
            ManyBody.wrapper alpha theta entityStrengths entities

        X entityConfigs ->
            let
                mapper id ent =
                    case Dict.get id entityConfigs of
                        Just { strength, position } ->
                            { ent | vx = ent.vx + (position - ent.x) * strength * alpha }

                        Nothing ->
                            ent
            in
            Dict.map mapper entities

        Y entityConfigs ->
            let
                mapper id ent =
                    case Dict.get id entityConfigs of
                        Just { strength, position } ->
                            { ent | vy = ent.vy + (position - ent.y) * strength * alpha }

                        Nothing ->
                            ent
            in
            Dict.map mapper entities

        Radial entityConfigs ->
            let
                mapper id ent =
                    case Dict.get id entityConfigs of
                        Just { strength, x, y, radius } ->
                            let
                                dx =
                                    ent.x - x

                                dy =
                                    ent.y - y

                                r =
                                    sqrt (dx ^ 2 + dy ^ 2)

                                k =
                                    (radius - r) * strength * alpha / r
                            in
                            { ent | vx = ent.vx + dx * k, vy = ent.vy + dy * k }

                        Nothing ->
                            ent
            in
            Dict.map mapper entities



{- Here is a sketch for a custom function implementation:
   Custom fun ->
       let
           erase : comparable -> Entity comparable a -> Entity comparable {}
           erase _ { x, y, vx, vy, id } =
               { x = x, y = y, vx = vx, vy = vy, id = id }

           maybeUpdate : Dict comparable (Entity comparable {}) -> comparable -> Entity comparable a -> Entity comparable a
           maybeUpdate newEntities id oldValue =
               case Dict.get id newEntities of
                   Just { x, y, vx, vy } ->
                       { oldValue | x = x, y = y, vx = vx, vy = vy }

                   Nothing ->
                       oldValue

           reunify : Dict comparable (Entity comparable {}) -> Dict comparable (Entity comparable a)
           reunify new =
               Dict.map (maybeUpdate new) entities
       in
       fun alpha (Dict.map erase entities)
           |> reunify
-}


{-| Apply `input` to the function `fn` `times` times.
-}
nTimes : (a -> a) -> Int -> a -> a
nTimes fn times input =
    if times <= 0 then
        input

    else
        nTimes fn (times - 1) (fn input)


{-| Advances the simulation a single tick, returning both updated entities and a new State of the simulation.
-}
tick : State comparable -> List (Entity comparable a) -> ( State comparable, List (Entity comparable a) )
tick (State state) nodes =
    let
        alpha =
            state.alpha + (state.alphaTarget - state.alpha) * state.alphaDecay

        dictNodes =
            List.foldl (\node -> Dict.insert node.id node) Dict.empty nodes

        newNodes =
            List.foldl (applyForce alpha) dictNodes state.forces

        updateEntity ent =
            { ent
                | x = ent.x + ent.vx * state.velocityDecay
                , vx = ent.vx * state.velocityDecay
                , y = ent.y + ent.vy * state.velocityDecay
                , vy = ent.vy * state.velocityDecay
            }
    in
    ( State { state | alpha = alpha }, List.map updateEntity <| Dict.values newNodes )


{-| Create a new simulation by passing a list of forces.
-}
simulation : List (Force comparable) -> State comparable
simulation forces =
    State
        { forces = forces
        , alpha = 1.0
        , minAlpha = 0.001
        , alphaDecay = 1 - 0.001 ^ (1 / 300)
        , alphaTarget = 0.0
        , velocityDecay = 0.6
        }


{-| You can set this to control how quickly the simulation should converge. The default value is 300 iterations.

Lower number of iterations will produce a layout quicker, but risk getting stuck in a local minimum. Higher values take
longer, but typically produce better results.

-}
iterations : Int -> State comparable -> State comparable
iterations iters (State config) =
    State { config | alphaDecay = 1 - config.minAlpha ^ (1 / toFloat iters) }


{-| Resets the computation. This is useful if you need to change the parameters at runtime, such as the position or
velocity of nodes during a drag operation.
-}
reheat : State comparable -> State comparable
reheat (State config) =
    State { config | alpha = 1.0 }


{-| Has the simulation stopped?
-}
isCompleted : State comparable -> Bool
isCompleted (State { alpha, minAlpha }) =
    alpha <= minAlpha


{-| This holds internal state of the simulation.
-}
type State comparable
    = State
        { forces : List (Force comparable)
        , alpha : Float
        , minAlpha : Float
        , alphaDecay : Float
        , alphaTarget : Float
        , velocityDecay : Float
        }


{-| `updatePortDistance portDistance state` updates the port distances in `state` to `portDistance`.
-}
updatePortDict : PortDict comparable -> State comparable -> State comparable
updatePortDict portDict (State state) =
    let
        helper force =
            case force of
                Links iter portDistance _ lnks ->
                    Links iter portDistance portDict lnks

                _ ->
                    force
    in
    State { state | forces = List.map helper state.forces }


{-| `updatePortDistance portDistance state` updates the port distances in `state` to `portDistance`.
-}
updatePortDistance : Float -> State comparable -> State comparable
updatePortDistance portDistance (State state) =
    let
        helper force =
            case force of
                Links iter _ portDict lnks ->
                    Links iter portDistance portDict lnks

                _ ->
                    force
    in
    State { state | forces = List.map helper state.forces }


{-| TODO: Change `source` and `target` to suite `ConnectedTo`.
-}
type alias LinkParam comparable =
    { source : ConnectedTo comparable
    , target : ConnectedTo comparable
    , distance : Float
    , strength : Float
    , bias : Float
    }


type alias DirectionalParam =
    { strength : Float
    , position : Float
    }


type alias RadialParam =
    { strength : Float
    , x : Float
    , y : Float
    , radius : Float
    }


{-| A force modifies nodes’ positions or velocities; in this context, a force can apply a classical physical force such
as electrical charge or gravity, or it can resolve a geometric constraint, such as keeping nodes within a bounding box
or keeping linked nodes a fixed distance apart.
-}
type Force comparable
    = Center Float Float
    | Collision Int Float (Dict comparable Float)
    | Links Int Float (PortDict comparable) (List (LinkParam comparable)) -- Links iterations portDistance linkParams
    | ManyBody Float (Dict comparable Float)
    | X (Dict comparable DirectionalParam)
    | Y (Dict comparable DirectionalParam)
    | Radial (Dict comparable RadialParam)



-- Update distance and strength


{-| 補助関数．Hyperlink の場合は少し distance を伸ばす．
-}
addPortDistance : Float -> ConnectedTo comparable -> ConnectedTo comparable -> Float
addPortDistance portDistance source target =
    let
        helper connectedTo =
            if PortGraph.isPort connectedTo then
                0

            else
                portDistance * 1
    in
    helper source + helper target


{-| `updateDistanceStrength distance strength linkParam` updates `distance` and `strength` in `linkParam`.
-}
updateDistanceStrength : Float -> Float -> Float -> LinkParam comparable -> LinkParam comparable
updateDistanceStrength portDistance distance strength linkParam =
    { linkParam | distance = distance + addPortDistance portDistance linkParam.source linkParam.target, strength = strength }


{-| `updateDistanceStrength distance strength linkParam` updates `distance` and `strength` in `linkParam`.
-}
updateDistanceStrengths : Float -> Float -> Force comparable -> Force comparable
updateDistanceStrengths distance strength force =
    case force of
        Links iters portDistance portDict linkParams ->
            Links iters portDistance portDict <| List.map (updateDistanceStrength portDistance distance strength) linkParams

        _ ->
            force


{-| `updateDistanceStrength distance strength linkParam` updates `distance` and `strength` in `linkParam`.
-}
updateDistanceStrengthsInState : Float -> Float -> State comparable -> State comparable
updateDistanceStrengthsInState distance strength (State state) =
    State { state | forces = List.map (updateDistanceStrengths distance strength) state.forces }



---


{-| The centering force translates nodes uniformly so that the mean position of all nodes (the center of mass) is at
the given position ⟨x,y⟩. This force modifies the positions of nodes on each application; it does not modify velocities,
as doing so would typically cause the nodes to overshoot and oscillate around the desired center. This force helps keep
nodes in the center of the viewport, and it does not distort their relative positions.
-}
center : Float -> Float -> Force comparable
center =
    Center


{-| The many-body (or n-body) force applies mutually amongst all nodes. It can be used to simulate gravity (attraction)
if the strength is positive, or electrostatic charge (repulsion) if the strength is negative.

Unlike links, which only affect two linked nodes, the charge force is global: it affects all nodes whose ids are passed
to it.

The default strength is -30 simulating a repulsing charge.

-}
manyBody : List comparable -> Force comparable
manyBody =
    manyBodyStrength -30


{-| This allows you to specify the strength of the many-body force.
-}
manyBodyStrength : Float -> List comparable -> Force comparable
manyBodyStrength strength =
    customManyBody 0.9 << List.map (\key -> ( key, strength ))


{-| This is the most flexible, but complex way to specify many body forces.

The first argument, let's call it _theta_, controls how much approximation to apply. The default value is 0.9.

To accelerate computation, this force implements the [Barnes–Hut approximation](http://en.wikipedia.org/wiki/Barnes%E2%80%93Hut_simulation) which takes O(n log n) per application where n is the number of nodes. For each application, a quadtree stores the current node positions; then for each node, the combined force of all other nodes on the given node is computed. For a cluster of nodes that is far away, the charge force can be approximated by treating the cluster as a single, larger node. The theta parameter determines the accuracy of the approximation: if the ratio w / l of the width w of the quadtree cell to the distance l from the node to the cell’s center of mass is less than theta, all nodes in the given cell are treated as a single node rather than individually. Setting this to 0 will disable the optimization.

This function also allows you to set the force strength individually on each node.

-}
customManyBody : Float -> List ( comparable, Float ) -> Force comparable
customManyBody theta =
    Dict.fromList >> ManyBody theta


{-| The link force pushes linked nodes together or apart according to the desired link distance. The strength of the
force is proportional to the difference between the linked nodes’ distance and the target distance, similar to a spring
force.

The link distance here is 30, the strength of the force is proportional to the number of links on each side of the
present link, according to the formule: `1 / min (count souce) (count target)` where `count` if a function that counts
links connected to those nodes.

-}
links :
    Float
    -> Float
    -> Maybe Float
    -> PortDict comparable
    -> List ( ConnectedTo comparable, ConnectedTo comparable )
    -> Force comparable
links distance portDistance maybeStrength portDict =
    List.map
        (\( source, target ) ->
            { source = source
            , target = target
            , distance = distance + addPortDistance portDistance source target
            , strength = Nothing
            }
        )
        >> customLinks 1 portDistance maybeStrength portDict


{-| Allows you to specify the link distance and optionally the strength. You must also specify the iterations count (the default in `links` is 1). Increasing the number of iterations greatly increases the rigidity of the constraint and is useful for complex structures such as lattices, but also increases the runtime cost to evaluate the force.
-}
customLinks :
    Int
    -> Float
    -> Maybe Float
    -> PortDict comparable
    -> List { source : ConnectedTo comparable, target : ConnectedTo comparable, distance : Float, strength : Maybe Float }
    -> Force comparable
customLinks iters portDistance maybeStrength portDict list =
    let
        counts =
            List.foldr
                (\{ source, target } d ->
                    d
                        |> Dict.update (extractNodeId source)
                            (Just << Maybe.withDefault 1 << Maybe.map ((+) 1))
                        |> Dict.update (extractNodeId target)
                            (Just << Maybe.withDefault 1 << Maybe.map ((+) 1))
                )
                Dict.empty
                list

        count connectedTo =
            Dict.get (extractNodeId connectedTo) counts |> Maybe.withDefault 0
    in
    list
        |> List.map
            (\{ source, target, distance, strength } ->
                { source = source
                , target = target
                , distance = distance
                , strength = Maybe.withDefault (1 / min (count source) (count target)) strength
                , bias = count source / (count source + count target)
                }
            )
        |> Links iters portDistance portDict


{-| The collision force simulates each node as a circle with a given radius and modifies their velocities to prevent the circles from overlapping.

Pass in the radius and a list of nodes that you would like the force to apply to.

-}
collision : Float -> List comparable -> Force comparable
collision radius =
    List.map (\item -> ( item, radius )) >> Dict.fromList >> Collision 1 1


{-| This allows you to specify a radius for each node specifically.

**Strength:** Overlapping nodes are resolved through iterative relaxation. For each node, the other nodes that are anticipated to overlap at the next tick (using the anticipated positions ⟨x + vx,y + vy⟩) are determined; the node’s velocity is then modified to push the node out of each overlapping node. The change in velocity is dampened by the force’s strength such that the resolution of simultaneous overlaps can be blended together to find a stable solution. Set it to a value [0, 1], `collision` defaults to 1.

**Iterations:** `collision` defaults to 1 - this makes the constraint more rigid, but makes the computation slower.

-}
customCollision : { iterations : Int, strength : Float } -> List ( comparable, Float ) -> Force comparable
customCollision params radii =
    Collision params.iterations params.strength (Dict.fromList radii)


{-| A positioning force along the X axis.
-}
towardsX : List { node : comparable, strength : Float, target : Float } -> Force comparable
towardsX configs =
    X (Dict.fromList (List.map (\{ node, strength, target } -> ( node, { strength = strength, position = target } )) configs))


{-| A positioning force along the Y axis.
-}
towardsY : List { node : comparable, strength : Float, target : Float } -> Force comparable
towardsY configs =
    Y (Dict.fromList (List.map (\{ node, strength, target } -> ( node, { strength = strength, position = target } )) configs))


{-| A positioning force that pushes towards the nearest point on the given circle.
-}
customRadial :
    List
        ( comparable
        , { strength : Float
          , x : Float
          , y : Float
          , radius : Float
          }
        )
    -> Force comparable
customRadial =
    Dict.fromList >> Radial
