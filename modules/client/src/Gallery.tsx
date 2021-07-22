import Button from "@material-ui/core/Button";
import CircularProgress from "@material-ui/core/CircularProgress";
import Paper from "@material-ui/core/Paper";
import TextField from "@material-ui/core/TextField";
import Typography from "@material-ui/core/Typography";
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
    minHeight: "850px",
  },
  photo: {
    padding: theme.spacing(4),
    display: "block",
    margin: "auto",
    maxHeight: "600px",
  }
}));

const Gallery = () => {
  const [newFilename, setNewFilename] = useState("");
  const [filename, setFilename] = useState("");
  const [image, setImage] = useState(""); // data url
  const [imgErrors, setImgErrors] = useState({} as { [key: string]: boolean });
  const classes = useStyles();

  useEffect(() => {
    console.log(`Got image errors`, imgErrors);
  }, [imgErrors]);

  useEffect(() => {
    setNewFilename(filename); // sync up new filename
    setImage(""); // reset image
    (async () => {
      if (!filename) return;
      const res = await axios.get(`/api/media/${filename}`, { responseType: "blob" });
      console.log(res);
      const reader = new window.FileReader();
      reader.readAsDataURL(res.data);
      reader.onload = () => {
        setImgErrors(old => ({ ...old, [filename]: false })); // reset img errors
        setImage(typeof reader.result === "string" ? reader.result : "");
      };
    })();
  }, [filename]);

  const handleFilenameChange = (event: React.ChangeEvent<{ value: any }>) => {
    setNewFilename(event.target.value);
  };

  const handleNext = async () => {
    if (!filename) return;
    const res = await axios.get(`/api/media/next/${filename}`);
    console.log(res);
    if (typeof res.data === "string") {
      setFilename(res.data);
    }
  };

  const handlePrev = async () => {
    if (!filename) return;
    const res = await axios.get(`/api/media/prev/${filename}`);
    if (typeof res.data === "string") {
      setFilename(res.data);
    }
  };

  const handleFetch = async () => {
    if (!newFilename) return;
    setFilename(newFilename);
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
        value={newFilename || ""}
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

      <Typography>
        {filename}
      </Typography>

      {image ? <Media
        src={image}
        alt={filename}
      /> : <CircularProgress/>}
    </Paper>
  );
};

export default Gallery;

