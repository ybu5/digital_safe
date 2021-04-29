// ELEX 7660 2020 Assigneent 3 Problem 1  
// output debouncedInput follows the input rawInput once it has been stable for 10ms   
// Yanming Bu 2020/3/12
`define delay_cycles 100000
module debouncedInput(
    input logic rawInput,
    output logic debouncedInput,
    input logic clk, reset_n
);
    int count;//count for how many cycles the rawinput has been stable 
    logic state, set_state;//state stores the previous input state
    //set_state is the state that output debouncedInput should be 

    //a flip flop that trigers at the possitive edge clk and reset at a active low reset
    always_ff @(posedge clk, negedge reset_n) begin
        //if reset_n is low, reset everything 
        if (~reset_n) begin
            count <= 0;
            state <= 0;
            set_state <= 0;
        end else begin
            state <= rawInput;//update the state with a rawInput 
            //if the stored state is not equal the rawInput 
            //then count reset to zero 
            if (state != rawInput) begin
                count <= 0;
            end else if (count<`delay_cycles-1) begin
                //else if the count is smaller than 9 cycles, count increments 
                count <= count + 1;
            end
            //if count reaches more than 10, set_state to be the previous state 
            if(count>=`delay_cycles-1)
                set_state = state;
        end
    end

    always_comb begin
        if (~reset_n) begin
            //if reset, output goes to zero 
            debouncedInput = 0;
        end else if (count >= `delay_cycles-1  ) begin
            //else if the rawInput is stabel for more than 10 cycles, the output follows the state 
            debouncedInput = state;
        end else begin
            //else if the rawInput is not stable, the output keeps the previous set states 
            debouncedInput = set_state;
        end
    end
endmodule