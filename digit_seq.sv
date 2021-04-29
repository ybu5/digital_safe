// ELEX 7660 202010 Final Project 
// Yanming Bu 2020/4/7
// This module reads the keypad inputs from users and 
// determines whether the kaypad input is matched, outputs a fail or pass
// display the user input on a 7-segment 
`define CODE 16'ha34f//the pin code 
module digit_seq(
    output logic [3:0] kpc,  // column select, active-low
    (* altera_attribute = "-name WEAK_PULL_UP_RESISTOR ON" *)
    input logic  [3:0] kpr,  // rows, active-low w/ pull-ups
	output logic [7:0] leds, // active-low LED segments 
    output logic [3:0] ct,   // " digit enables
    input logic  reset_n, clk,
    output logic pass, fail //output user input passed or failed
);
    logic [3:0] kpNum; 		// keypad output
    logic [1:0] digit;       // 7-seg display digit currently selected
   logic [7:0] delayCnt;    // delay count to slow down digit cycling on display
   logic kphit;             // keypad button press indicator
   logic [15:0] passcode;   //passcode 
   logic [15:0] inputs;     //user inputs
   logic [2:0] count;       //indicates which digit user inputs are 
   logic delete, delete_reset;//delete state 
    logic [3:0] displayNum;	// number to display on 7-seg
    logic pincode_pass;     //high if user inputs match with passcode 
    logic kphit_state, kphit_pre, kphit_debounce;//kphit different states 

    //modules to read keypad, decode 7 segment, and debounce keypad inputs 
    colseq colseq_digit (.clk,.reset_n,.kpr,.kpc);
    kpdecode kpdecode_digit (.kphit,.num(kpNum), .kpr, .kpc);
    decode7 decode7_digit (.num(displayNum),.leds);
    debouncedInput debouncedInput_digit (.rawInput(kphit),.debouncedInput(kphit_debounce),.clk,.reset_n);

    always_comb begin
        passcode = `CODE;//set the passcode 
        if (passcode == inputs) begin
            pincode_pass = 1;//if passcode matches with user inputs, set pincode_pass to 1
        end else begin
            pincode_pass = 0;//else set it to zero 
        end

        case( digit )//set the displaynum according to the user input 
            3 : displayNum = inputs[15:12];
            2 : displayNum = inputs[11:8] ;
            1 : displayNum = inputs[7:4] ;
            0 : displayNum = inputs[3:0] ;
		default: 
            displayNum = 'hf ; 
        endcase

        ct =  1'b1 << digit;
    end

    always_ff @(posedge clk) begin
    // only switch to next digit when count rolls over for crisp display
	    delayCnt <= delayCnt + 1'b1;  
	    if (delayCnt == 0)
		    if (digit >= 4)
			    digit <= '0;
		    else
			    digit <= digit + 1'b1 ;
	end

    always_ff @(posedge clk, negedge reset_n) begin
        if (~reset_n) begin//reset 
            delete <= 0;
            delete_reset <= 0;
            pass <= 0;
            count <= 0;
            inputs <= 0;
            fail <= 0;
        end else begin
            //if there is a rising edge for kphit 
            if (kphit_state == 1&&kphit_pre==0) begin
                if (kpNum == 4'he) begin//if the input num is e, delet the last input 
                    //make sure delete only happends one cycle
                    if(delete_reset)begin
                        delete <= 0;
                        delete_reset <= 0;
                    end 
                    else begin
                        delete <= 1;
                        delete_reset <= 1;
                    end
                    if(count>0)//if count is bigger than zero, count--
                        count <= count - 1;
                    case(count)//determine which input to delete according to count 
                        1:inputs[3:0]<=0;
                        2:inputs[7:4]<=0;
                        3:inputs[11:8]<=0;
                    endcase
                end 
                else begin//if input num is not e 
                    case(count)//store the input num to input according to count  
                        0:inputs[3:0]<=kpNum;
                        1:inputs[7:4]<=kpNum;
                        2:inputs[11:8]<=kpNum;
                        3:inputs[15:12]<=kpNum;
                    endcase
                    if(count<=3)//increment count 
                        count <= count + 1; 
                end
            end 
            else if (pincode_pass) begin
                pass <= 1;//if pincode_pass is high, output pass is high h
                fail <= 0;//set fail to zero 
            end else if(count==4) begin
                count <= 0;//else if user inputed 4 number without a pass 
                inputs <= 0;//fail set to high 
                fail <= 1;//reset the count and previous input 
            end
            //store different state of kphit_debouce 
            kphit_state <= kphit_debounce;
            kphit_pre <= kphit_state;
            
        end
    end
endmodule

