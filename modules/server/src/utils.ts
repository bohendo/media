import fs from "fs";

import pino from "pino";
import prettifier from "pino-pretty";

import { env } from "./env";

export const getLogger = (level = "warn"): pino.Logger => pino({
  level,
  prettyPrint: {
    colorize: true,
    ignore: "pid,hostname,module",
    messageFormat: `[{module}] {msg}`,
    translateTime: true,
  },
  prettifier,
});
export const log = getLogger(env.logLevel).child({ module: "Utils" });

export const STATUS_SUCCESS = 200;
export const STATUS_NOT_FOUND = 404;
export const STATUS_YOUR_BAD = 400;
export const STATUS_MY_BAD = 500;

export const getLogAndSend = (res) => (message, code = STATUS_SUCCESS): void => {
  if (code === STATUS_SUCCESS) {
    log.child({ module: "Send" }).info(`Success: ${
      typeof message === "string" ? message : JSON.stringify(message, null, 2)
    }`);
  } else {
    log.child({ module: "Send" }).warn(`Error ${code}: ${message}`);
  }
  res.status(code).send(message);
  return;
};
