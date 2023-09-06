
console.log("Start running first node util to print args.");

const args = process.argv;
  
console.log(args);
args.forEach((e, idx) => {
  // The process.argv array contains
  // Node.js executable absolute
  // path as first element
  if (idx === 0) {
    console.log(`Exec path: ${e}`);
  }
  
  // Absolute file path is the second element
  // of process.argv array
  else if (idx === 1) {
    console.log(`File Path: ${e}`);
  }
  
  // Rest of the elements are the command
  // line arguments the we pass
  else {
    console.log(`Argument ${idx - 1}: ${e}`);
  }
});
