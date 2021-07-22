import express from "express";

import { logger } from "./utils";

const log = logger.child({ module: "Media" });

export const mediaRouter = express.Router();

mediaRouter.use((req, res, next) => {
  log.info(`Got request for media at path: ${req.path}`);
  next();
});
