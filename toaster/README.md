https://github.com/nels-o/toaster

$ ./toast.exe
No args provided.

Welcome to toast.
Provide toast with a message and display it-
via the graphical notification system.
-Nels

---- Usage ----
toast <string>|[-t <string>][-m <string>][-p <string>]

---- Args ----
<string>                | Toast <string>, no add. args will be read.
[-t] <title string>     | Displayed on the first line of the toast.
[-m] <message string>   | Displayed on the remaining lines, wrapped.
[-p] <image URI>        | Display toast with an image
[-q]                    | Deactivate sound (quiet).
[-w]                    | Wait for toast to expire or activate.
?                       | Print these intructions. Same as no args.
Exit Status     :  Exit Code
Failed          : -1
Success         :  0
Hidden          :  1
Dismissed       :  2
Timeout         :  3

---- Image Notes ----
Images must be .png with:
        maximum dimensions of 1024x1024
        size <= 200kb
These limitations are due to the Toast notification system.
This should go without saying, but windows style paths are required.
