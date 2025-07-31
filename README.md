Fundwave App

A fintech App

1.

2

**************************
### Bugs

1. First github workflow attempt failled - 

```
> fundwave-app@1.0.0 build /app
> react-scripts build
Creating an optimized production build...
Failed to compile.
./src/index.js
Error: [BABEL] /app/src/index.js: Requires Babel "^7.16.0", but was loaded with "7.12.3". If you are sure you have a compatible version of @babel/core, it is likely that something in your build process is loading the wrong version. Inspect the stack trace of this error to look for the first entry that doesn't mention "@babel/core" or "babel-core" to see what is calling Babel. (While processing: "/app/node_modules/babel-preset-react-app/index.js$0$2").....
``` 


### Actions to fix error
Issue is likely connected to a dependency version -  the Babel version. 
Update the latest babel version 
```
npm install @babel/core@^7.16.0
``` 

### Result: 
workflow successful

