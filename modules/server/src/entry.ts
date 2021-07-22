import bodyParser from "body-parser";
import express from "express";

import { authRouter } from "./auth";
import { mediaRouter } from "./media";
import { env } from "./env";
import { logger, getLogAndSend, STATUS_NOT_FOUND } from "./utils";

const log = logger.child({ module: "Entry" });
log.info(`Starting server in env: ${JSON.stringify(env, null, 2)}`);

////////////////////////////////////////
// Begin Express Pipeline

const app = express();

app.use(authRouter);
app.get("/auth", (req, res) => { res.send("Success"); });

app.use(bodyParser.json({ type: ["application/json"] }));
app.use(bodyParser.raw({ limit: env.maxUploadSize, type: [
  "application/octet-stream",
  "application/x-git-receive-pack-request",
  "application/x-git-upload-pack-request",
  "image/*",
  "multipart/*",
  "video/*",
] }));
app.use(bodyParser.text({ type: ["text/*"] }));

app.use(mediaRouter);

app.use((req, res) => {
  return getLogAndSend(res)(`not found`, STATUS_NOT_FOUND);
});

// End Express Pipeline
////////////////////////////////////////

app.listen(env.port, () => {
  log.info(`Server is listening on port ${env.port}`);
});
