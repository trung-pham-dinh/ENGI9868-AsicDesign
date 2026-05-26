--binary 
--trace  --trace-structs --trace-fst --trace-max-array 512 --trace-max-width 64 
--sv --timing 
-O3 --compiler gcc -CFLAGS -std=gnu++20
-x-initial unique
-x-assign unique
--assert
--build -j 0 --quiet

--Mdir run_dir_verilator
-DDV_FORMAL=1

// -Wall -Wno-UNUSEDSIGNAL
