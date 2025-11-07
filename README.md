# 📐 Inverse Matrix Calculator (Gauss-Jordan Method) 
# 👤 Author : MattCarneiiro
This project implements a calculator to determine the inverse matrix ($A^{-1}$) of a square matrix of order $N$ (dynamic), using the Gauss-Jordan Elimination algorithm in conjunction with the Augmented Matrix technique $[A|I]$.The code was developed in MIPS Assembly for simulation in environments such as MARS (MIPS Assembler and Runtime Simulator), and it uses dynamic memory allocation (the sbrk syscall).
## ✨ Features
### -Dynamic Size ($N$): The user can define the size of the square matrix $N$, with a limit of $2 \le N \le 10$.
### -Dynamic Allocation: Uses the sbrk syscall to allocate the necessary memory for the Augmented Matrix $[A|I]$, adapting to the chosen $N$.
### -Gauss-Jordan Implementation: Applies the elimination to transform $[A|I]$ into $[I|A^{-1}]$.
### -Pivot Normalization: Divides the pivot row by the pivot element.
### -Elimination: Annuls the elements above and below the pivot.
### -Singularity Detection: Checks if the matrix is singular (zero determinant, i.e., if a pivot is zero), reporting that the inverse does not exist.
### -Friendly Interface: Prints prompts for data entry and displays the Original Matrix and the Inverse Matrix (if it exists) with formatting.
## 📚 Usage Instructions (MARS)
### Compilation: Load the file PROJETOMATRIZ.asm into the MARS simulator.
### Execution: Click on Run and then Go.
### Input:
### -The program will ask for the matrix size $N$ ($2 \le N \le 10$).
### -Next, it will prompt for the input of the $N \times N$ elements of matrix $A$ in floating-point format.
### Output:
### -The program will display the Original Matrix $A$.
### -If the matrix is invertible, it will display the Inverse Matrix $A^{-1}$ (the last $N$ columns of the final Augmented Matrix).
### -If the matrix is singular, it will display the appropriate error message.

