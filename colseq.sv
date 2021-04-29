// ELEX 7660 ELEX 7660 201710 Lab2 
//a simple state machine, output kpc cycles through 0111, 1011, 1110, 0111. 
//input kpr determine if a button is pressed
//active low reset, and possitive clock edge 
// Yanming Bu 2021-01
module colseq ( output logic [3:0] kpc,
                input logic [3:0] kpr,
                input logic clk, reset_n);

    //flip flop trigger at possitive clock edge, active low reset
    always_ff @(posedge clk, negedge reset_n) begin
        
        //reset kpc to 0111, when reset is low 
        if (~reset_n)
            kpc <= 4'b0111;
        else begin
            
            //check if the button is pressed 
            if (kpr == 4'b1111)
                //if no button is pressed, shift kpc 1 bit to the right 
                //and replce the most significant bit with 1 
                //when kpc reach the last cycle (1110), set it to 0111
                if(kpc == 4'b1110)
                    kpc <= 4'b0111;
                else begin
                    kpc <= kpc>>1|4'b1000;
                end
            else begin
                //is a button is pressed, hold the value of kpc 
                kpc <= kpc;
            end
        end
        
    end
endmodule
