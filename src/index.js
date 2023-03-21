import "./main.css";

import { Elm } from "./Main.elm";
import * as serviceWorker from "./serviceWorker";

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
    const [_, k, graph, value] = LambdaGT.extractk(result);
    global_cont = k[1];
    const messageJSON = JSON.stringify({
      graph: JSON.parse(graph),
      isEnded: global_cont == null,
      info: value,
    });
    app.ports.messageReceiver.send(messageJSON);
  } catch (e) {
    alert(e);
  }
});

const proceed = () => {
  try {
    const result = global_cont();
    const [_, k, graph, value] = result[1];
    global_cont = k[1];
    const messageJSON = JSON.stringify({
      graph: JSON.parse(graph),
      isEnded: global_cont == null,
      info: value,
    });
    app.ports.messageProceedReceiver.send(messageJSON);
  } catch (e) {
    alert(e);
  }
};

// When a command goes to the `sendMessage` port, we pass the message
// along to the WebSocket.
app.ports.sendMessageProceed.subscribe(function (message) {
  // receive a message from elm frontent
  console.log("Proceed", message);
  if (!global_cont) {
    alert("cannot proceed more");
    return;
  }

  proceed();
});

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
