Readme.txt
Macroscopic and Microscopie Unmixing

The code in this directory is an evolution of the code that Ryan Close wrote for his dissertation research.    The changes included:

(1) Changing the lookup tables to calculations
(2) General speedups
(3) Changing the algorithm to optimize the difference between the pixels and the linear mixture, normalized by the proportion of the microscopic mixture.

(F1) The function that does the unmixing is

       MacMicUnmixDEM(Data, parameters, degrees)

       The parameters are set by the function

       MacMicUnmixParametersDEM





