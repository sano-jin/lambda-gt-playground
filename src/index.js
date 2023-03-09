import "./main.css";

import { Elm } from "./Main.elm";
import * as serviceWorker from "./serviceWorker";

// Example of graphs.
const graph = (n) => ({
  atoms: [
    {
      id: 0,
      label: "Cons",
      ports: [
        { id: 0, label: "1", to: { nodeId: 1, portId: 0 } },
        { id: 1, label: "2", to: { nodeId: 2, portId: 2 } },
        { id: 2, label: "3", to: { nodeId: 7 } },
      ],
    },
    {
      id: 1,
      // label: "1",
      label: (n + 1).toString(),
      ports: [{ id: 0, label: "1", to: { nodeId: 0, portId: 0 } }],
    },
    {
      id: 2,
      label: "Cons",
      ports: [
        { id: 0, label: "1", to: { nodeId: 3, portId: 0 } },
        { id: 1, label: "2", to: { nodeId: 4, portId: 2 } },
        { id: 2, label: "3", to: { nodeId: 0, portId: 1 } },
      ],
    },
    {
      id: 3,
      // label: "2",
      label: (n + 2).toString(),
      ports: [{ id: 0, label: "1", to: { nodeId: 2, portId: 0 } }],
    },
    {
      id: 4,
      label: "Cons",
      ports: [
        { id: 0, label: "1", to: { nodeId: 5, portId: 0 } },
        { id: 1, label: "2", to: { nodeId: 6, portId: 0 } },
        { id: 2, label: "3", to: { nodeId: 2, portId: 1 } },
      ],
    },
    {
      id: 5,
      // label: "3",
      label: (n + 3).toString(),
      ports: [{ id: 0, label: "1", to: { nodeId: 4, portId: 0 } }],
    },
    {
      id: 6,
      label: "Nil",
      ports: [{ id: 0, label: "1", to: { nodeId: 4, portId: 1 } }],
    },
  ],
  hlinks: [{ id: 7, label: "X", to: [{ nodeId: 0, portId: 2 }] }],
});

// const graphJSON = JSON.stringify(graph);
// console.log(graph(0), graphJSON);

const app = Elm.Main.init({
  node: document.getElementById("root"),
});

// When a command goes to the `sendMessage` port, we pass the message
// along to the WebSocket.
app.ports.sendMessage.subscribe(function (message) {
  console.log("Send", message);
  myCallback();
});

// When a message comes into our WebSocket, we pass the message along
// to the `messageReceiver` port.
// socket.addEventListener("message", function (event) {
//   app.ports.messageReceiver.send(event.data);
// });

let counter = 0;
let isEnded = false;
function myCallback() {
  // Your code here
  // Parameters are purely optional.
  // console.log("fuga");
  const data = `fuga-${counter}`;
  counter += 1;
  // app.ports.messageReceiver.send(data);
  // app.ports.messageReceiver.send(graphJSON);

  const messageJSON = JSON.stringify({
    graph: graph(counter),
    isEnded: isEnded,
    info: data,
  });
  isEnded = !isEnded;
  app.ports.messageReceiver.send(messageJSON);
}

const intervalID = setInterval(myCallback, 5000);

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
