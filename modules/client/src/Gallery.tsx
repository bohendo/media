import React, { useState } from "react";
import Paper from "@material-ui/core/Paper";
import TextField from "@material-ui/core/TextField";
import {
  createStyles,
  makeStyles,
  Theme,
} from "@material-ui/core/styles";

const useStyles = makeStyles((theme: Theme) => createStyles({
  paper: {
    flexGrow: 1,
    overflow: "auto",
    margin: theme.spacing(4),
    padding: theme.spacing(4),
    minHeight: "100%",
  },
}));

const Gallery = () => {
  const [filename, setFilename] = useState("");
  const classes = useStyles();

  const handleFilenameChange = (event: React.ChangeEvent<{ value: any }>) => {
    setFilename(event.target.value);
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
    </Paper>
  );
};

export default Gallery;
