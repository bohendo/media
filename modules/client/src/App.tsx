import React from "react";
import CssBaseline from "@material-ui/core/CssBaseline";
import {
  createMuiTheme,
  createStyles,
  makeStyles,
  Theme,
  ThemeProvider,
} from "@material-ui/core/styles";

import "./App.css";
import Gallery from "./Gallery";

const darkTheme = createMuiTheme({
  palette: {
    primary: {
      main: "#deaa56",
    },
    secondary: {
      main: "#e699a6",
    },
    type: "dark",
  },
});

const useStyles = makeStyles((theme: Theme) => createStyles({
  main: {
    flexGrow: 1,
    overflow: "auto",
    margin: theme.spacing(4),
  },
}));

const App = () => {
  const classes = useStyles();
  return (
    <ThemeProvider theme={darkTheme}>
      <CssBaseline />
      <main className={classes.main}>
        <Gallery/>
      </main>
    </ThemeProvider>
  );
};

export default App;
