import fs from "fs";

import express from "express";

import {
  logger,
  STATUS_NOT_FOUND,
  STATUS_MY_BAD,
} from "./utils";

const log = logger.child({ module: "Media" });

export const mediaRouter = express.Router();

const filelistCache = {} as { [key: string]: string[] };
const getFileList = (category: string): string[] => {
  try {
    if (!filelistCache[category]) {
      filelistCache[category] = fs.readdirSync(`/media/${category}`);
      filelistCache[category].sort();
      log.info(`Got new ${category} filelist: ${filelistCache[category].splice(0, 100)},etc`);
    }
    return filelistCache[category];
  } catch (e) {
    log.warn(e.message);
    return [];
  }
};

mediaRouter.get(`/next/:category/:filename`, (req, res) => {
  const { category, filename }  = req.params;
  const filelist = getFileList(category);
  if (!filelist?.length) {
    res.send("Not Found", STATUS_NOT_FOUND);
  }
  let nextIndex = filelist.findIndex(file => file === filename) + 1;
  if (nextIndex === filelist.length) {
    nextIndex = 0;
  }
  res.send(`${category}/${filelist[nextIndex]}`);
});

mediaRouter.get(`/prev/:category/:filename`, (req, res) => {
  const { category, filename }  = req.params;
  const filelist = getFileList(category);
  if (!filelist?.length) {
    res.send("Not Found", STATUS_NOT_FOUND);
  }
  let prevIndex = filelist.findIndex(file => file === filename) - 1;
  if (prevIndex < 0) {
    prevIndex = filelist.length - 1;
  }
  res.send(`${category}/${filelist[prevIndex]}`);
});

mediaRouter.get(`/:category/:filename`, (req, res) => {
  const { category, filename }  = req.params;
  if (category === "private") {
    log.warn(`Got request for ${category} file: ${filename}`);
  } else {
    log.info(`Got request for ${category} file: ${filename}`);
  }
  res.sendFile(
    `${category}/${filename}`,
    { root: "/media", dotfiles: "deny" },
    (err) => {
      if (err) {
        log.error(err);
        if (err.message.includes("no such file)")) {
          res.send("Not Found", STATUS_NOT_FOUND);
        } else {
          res.send("Oh No", STATUS_MY_BAD);
        }
      } else {
        log.info(`Successfully sent ${filename}`);
      }
    },
  );
});
