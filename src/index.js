import "./main.css";

import { Elm } from "./Main.elm";
import * as serviceWorker from "./serviceWorker";
// import * as LambdaGT from "./runtime.js";

const app = Elm.Main.init({
  node: document.getElementById("root"),
});

/** Global variables.
 */
let global_cont = null;
let global_graph = null;

// When a command goes to the `sendMessage` port, we pass the message
// along to the WebSocket.
app.ports.sendMessage.subscribe(function (code) {
  // receive a message from elm frontent
  console.log("Send", code);
  try {
    const result = LambdaGT.rungrad(code);
    console.log("result", result);
    console.log("LambdaGT.extractk", LambdaGT.extractk);
    console.log("LambdaGT.extractk(result)", LambdaGT.extractk(result));

    const [_, k, graph, value] = LambdaGT.extractk(result);
    console.log(k);
    global_cont = k[1];

    console.log("graph", graph);
    const messageJSON = JSON.stringify(
      {
        graph: JSON.parse(graph),
        isEnded: global_cont == null,
        info: "hogehoge",
      },
      null,
      " "
    );
    console.log(messageJSON);
    app.ports.messageReceiver.send(messageJSON);
  } catch (e) {
    alert(e);
  }
});

const proceed = () => {
  try {
    console.log("global_cont", global_cont);
    const result = global_cont();
    console.log("result", result);
    console.log("LambdaGT.extractk(result)", LambdaGT.extractk(result));

    const res = LambdaGT.extractk(result);
    console.log("res", res);
    const [_, k, graph, value] = result[1];

    console.log(k);
    global_cont = k[1];

    console.log("graph", graph);
    const messageJSON = JSON.stringify(
      {
        graph: JSON.parse(graph),
        isEnded: global_cont == null,
        info: "hogehoge",
      },
      null,
      " "
    );
    console.log(messageJSON);
    app.ports.messageProceedReceiver.send(messageJSON);
  } catch (e) {
    alert(e);
  }
};

// When a command goes to the `sendMessage` port, we pass the message
// along to the WebSocket.
app.ports.sendMessageProceed.subscribe(function (message) {
  // receive a message from elm frontent
  console.log("Send", message);
  // myCallback();
  if (!global_cont) {
    alert("cannot proceed more");
    return;
  }

  proceed();
});

// When a message comes into our WebSocket, we pass the message along
// to the `messageReceiver` port.
// socket.addEventListener("message", function (event) {
//   app.ports.messageReceiver.send(event.data);
// });

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
