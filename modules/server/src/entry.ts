import express from "express";

import { env } from "./env";
import { log, getLogAndSend, STATUS_NOT_FOUND } from "./utils";

log.info(`Starting server in env: ${JSON.stringify(env, null, 2)}`);

const app = express();

app.use(express.json());

app.use((req, res) => {
  return getLogAndSend(res)(`not found`, STATUS_NOT_FOUND);
});

app.listen(env.port, () => {
  log.info(`Server is listening on port ${env.port}`);
});
