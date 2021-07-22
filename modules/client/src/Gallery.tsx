import Paper from "@material-ui/core/Paper";
import TextField from "@material-ui/core/TextField";
import Button from "@material-ui/core/Button";
import {
  createStyles,
  makeStyles,
  Theme,
} from "@material-ui/core/styles";
import React, { useEffect, useState } from "react";
import axios from "axios";

const useStyles = makeStyles((theme: Theme) => createStyles({
  paper: {
    flexGrow: 1,
    overflow: "auto",
    margin: theme.spacing(4),
    padding: theme.spacing(4),
    minHeight: "100%",
  },
  photo: {
    padding: theme.spacing(4),
    display: "block",
    margin: "auto",
    maxWidth: "100%",
  }
}));

const Gallery = () => {
  const [filename, setFilename] = useState("");
  const [image, setImage] = useState(""); // data url
  const [imgErrors, setImgErrors] = useState({} as { [key: string]: boolean });
  const classes = useStyles();

  useEffect(() => {
    console.log(`Got image errors`, imgErrors);
  }, [imgErrors]);

  const handleFilenameChange = (event: React.ChangeEvent<{ value: any }>) => {
    setFilename(event.target.value);
  };

  const handleNext = async () => {
    if (!filename) return;
    const res = await axios.get(`/api/media/next/${filename}`);
    console.log(res);
    if (typeof res.data === "string") {
      setFilename(res.data);
      handleFetch();
    }
  };

  const handlePrev = async () => {
    if (!filename) return;
    const res = await axios.get(`/api/media/prev/${filename}`);
    if (typeof res.data === "string") {
      setFilename(res.data);
      handleFetch();
    }
  };

  const handleFetch = async () => {
    if (!filename) return;
    const res = await axios.get(`/api/media/${filename}`, { responseType: "blob" });
    console.log(res);
    const reader = new window.FileReader();
    reader.readAsDataURL(res.data); 
    reader.onload = () => {
      setImage(typeof reader.result === "string" ? reader.result : "");
    };
  };

  const Media = ({
    alt,
    src,
  }: {
    alt: string;
    src: string;
  }) => {
    return (!imgErrors[alt]
      ? <img
        className={classes.photo}
        onError={() => { if (!imgErrors[alt]) setImgErrors(old => ({ ...old, [alt]: true })); }}
        src={src}
        alt={alt}
      />
      : <video
        className={classes.photo}
        controls
        src={src}
      />
    );
  };

  return (
    <Paper className={classes.paper}>
      <TextField
        autoComplete="off"
        value={filename || ""}
        helperText="Path to target file"
        id="filename"
        fullWidth
        label="Filename"
        margin="normal"
        name="filename"
        onChange={handleFilenameChange}
        variant="outlined"
      />

      <Button
        onClick={handlePrev}
        variant="contained"
        color="primary"
      >
        Previous
      </Button>

      <Button
        onClick={handleFetch}
        variant="contained"
        color="primary"
      >
        Fetch
      </Button>

      <Button
        onClick={handleNext}
        variant="contained"
        color="primary"
      >
        Next
      </Button>

      {image ? <Media
        src={image}
        alt={filename}
      /> : null}
    </Paper>
  );
};

export default Gallery;

