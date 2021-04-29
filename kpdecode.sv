// ELEX 7660 202010 Lab 3
// Yanming Bu 2020/1/28
//output kphit goes high when a button is pressed 
//output num indicates which num is presses on the key pad 
//differnet inputs kpr and kpc comb indicates which key   
module kpdecode(
    output logic kphit,
    output logic [3:0] num,
    input logic [3:0] kpr, kpc
);
    always_comb begin
        num = 0;// assign default state to num

        //check through kpr in its four state
        //within each kpr states, check through four states for kpc
        //16 different states matches with a different num in hex 
        case (kpr)
            4'b1110: begin
                case (kpc)
                    4'b1110: num = 4'hd;
                    4'b1101: num = 4'hf;
                    4'b1011: num = 4'h0;
                    4'b0111: num = 4'he;
                    default: begin
                        
                    end
                endcase
                kphit = 1;
            end

            4'b1101: begin
                case (kpc)
                    4'b1110: num = 4'hc;
                    4'b1101: num = 4'h9;
                    4'b1011: num = 4'h8;
                    4'b0111: num = 4'h7;
                    default: begin
                        
                    end
                endcase
                kphit = 1;
            end

            4'b1011: begin
                case (kpc)
                    4'b1110: num = 4'hb;
                    4'b1101: num = 4'h6;
                    4'b1011: num = 4'h5;
                    4'b0111: num = 4'h4;
                    default: begin
                        
                    end
                endcase
                kphit = 1;
            end

            4'b0111: begin
                case (kpc)
                    4'b1110: num = 4'ha;
                    4'b1101: num = 4'h3;
                    4'b1011: num = 4'h2;
                    4'b0111: num = 4'h1;
                    default: begin
                        
                    end
                endcase
                kphit = 1;
            end
            default: begin
                kphit = 0;
            end
        endcase

        // if kpr is 15, not key is pressed 
        //else a key is pressed, kphit goes high 
        //if(kpr==15)
            //kphit = 0;
        //else if(kpr==4'b0111)
        //    kphit = 1;
        
    end
    //kpr==0111||kpr==1011||kpr==1101||kpr==1110
endmodule