// ELEX 7660 202010 Final Project 
// Yanming Bu 2020/4/7
// This controls the the servo position
// It takes clock, active low reset, and the angle position from 0-180 in degree 
// and outputs the PWM to move the servo to the desire position  
`define DIVISOR 23000 //23000 clk cycles can create a 50Hz pules 
`define K 6 //the mapping scale 0-180 degree to 10-20ns 
module servo_driver(
    input logic clk, reset_n,
    input logic[7:0] angle_pos,
    output logic signal
);

    int cycle_high;//indicates the amount of cycles the output signal should be high for 
    int cycle_low;//indicates the amount of cycles the output signal should be low for 
    int count;//indicates how many clk cycles has passed 
    always_comb begin
        //cycle_high and cycle_low determine how many clk cycles th eoutput signal should stay 
        //high/low for 
        cycle_high = angle_pos*`K + 1100;//map the input angle in degree to clk cycles 
        cycle_low = `DIVISOR - cycle_high;
    end  

    always_ff @(posedge clk, negedge reset_n) begin
        if (~reset_n) begin//reset count and signal 
            count <= 0;
            signal <= 0;
        end else begin
            count = count + 1;//counting the clk cycles 
            //if the signal is zero and count is bigger than how many cycle the output 
            //should stay low for, then reset count and set the signal to 1
            if(count>cycle_low&&signal==0)begin
                count <= 0;
                signal <= 1;
            end 
            //else if the signal is 1, and count is bigger than the cycle amount that 
            //signal should stay high for, then reset count and set the signal to 0
            else if(count>cycle_high&&signal) begin
                count <= 0;
                signal <= 0;
            end
        end
    end
endmodule