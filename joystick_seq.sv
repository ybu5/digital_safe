// ELEX 7660 202010 Final Project 
// Yanming Bu 2020/4/7
// This module reads the joystick position and determine whether the joystick input matches with 
// the pass sequence, determine the 7-segment display message 

`define UP 4'h1
`define DOWN 4'h2
`define LEFT 4'h3
`define RIGHT 4'h4
`define MID 4'h0
`define SAMPDELAY 50
module joystick_seq (  output logic [3:0] kpc,  // column select, active-low
              (* altera_attribute = "-name WEAK_PULL_UP_RESISTOR ON" *)
              input logic  [3:0] kpr,  // rows, active-low w/ pull-ups
			  output logic [7:0] leds, // active-low LED segments 
              output logic [3:0] ct,   // " digit enables
              output logic pass,fail, //pass the input or fail 
			  output ADC_CONVST, ADC_SCK, ADC_SDI,
              input ADC_SDO,
              input logic  reset_n, clk) ;

   logic [11:0] adcValue;   // ADC result    
   logic [3:0] displayNum;	// number to display on 7-seg
   logic [3:0] kpNum; 		// keypad output
   logic [1:0] digit;       // 7-seg display digit currently selected
   logic [7:0] delayCnt;    // delay count to slow down digit cycling on display
    enum{setY,readY,setX,readX,eval,do_none} seq; //joystick reading sequence 
   logic [2:0] chanSelet;  //which channle to sample 
   logic [7:0] reading; //current reading of the most significant digit of ADC result in hex 
   logic [2:0] count; //indicactes the amount of the inputs 
   logic kphit_state, kphit_pre, kphit_debounce; //store the different states of kbhit 
   logic [15:0] position, pass_seq; //the pass sequence and the user inputs 
   logic [3:0] decision;//decide the user input 
   logic seq_pass;//input sequece matches with the set sequence 
   logic [5:0] sample_delay;//the amount of delay cycles  
  
   // modules to decode joystick, read the keypade input, and debounce keypad input
   decode_joystick decode_joystick0 (.num(displayNum), .leds) ;
   kpdecode kpdecode_joy (.num(kpNum), .kphit, .kpr, .kpc) ;
   colseq  colseq_joy  (.kpc, .kpr, .reset_n, .clk) ;
   debouncedInput debouncedInput_joy (.rawInput(kphit),.debouncedInput(kphit_debounce),.clk(clk),.reset_n);
 
   // ADC interface module
   adcinterface(.clk, .reset_n, .chan(chanSelet),.result(adcValue),
	.ADC_CONVST, .ADC_SCK, .ADC_SDI, .ADC_SDO );

    always_ff @(posedge clk, negedge reset_n) begin
        if(~reset_n) begin//reset 
            chanSelet <= 0;
            seq <= do_none;
            reading <= 0;
            count <= 0;
            position <= 0;
            pass <= 0;
            fail <= 0;
            sample_delay <= `SAMPDELAY;
        end else begin
            //store the kphit state 
            kphit_state <= kphit_debounce;
            kphit_pre <= kphit_state;
            //if there is a positive edge for kphit 
            if(kphit_state == 1&&kphit_pre==0)begin
                //if c is press, get ready to sample the y axis 
                if(kpNum == 4'hc)begin
                    seq <= setY;
                end else if(kpNum == 4'he) begin
                    //else if e is press, delete the last user input 
                    case(count)
                        1:position[3:0]<=`MID;
                        2:position[7:4]<=`MID;
                        3:position[11:8]<=`MID;
                    endcase
                    if(count>0)
                        count <= count - 1;//if there is a last input, delete it 
                end
            end

            //state mashine cycle to sample x and y axis and store the joystick input 
            if(seq == setY)begin
                //if sequence is getting ready to sample y axis 
                chanSelet[0] <= 1;//set the sample channel 
                sample_delay = sample_delay - 1;
                if(sample_delay == 0) begin//wait for the delay cycles
                    seq <= readY;//move to readY sequence 
                    sample_delay <= `SAMPDELAY;//reset the delay cycles 
                end
            end else if (seq == readY) begin
                reading[3:0] <= adcValue[11:8];//if readY sequence, update the reading 
                seq <= setX;//move to sample x sequence 
            end else if (seq == setX) begin
                chanSelet[0] <= 0;//set the sample channelto x axis 
                sample_delay = sample_delay - 1;
                if(sample_delay == 0) begin
                    seq <= readX;//wait for delay cycles and move to reading x sequence 
                    sample_delay <= `SAMPDELAY;//reset delat cycles 
                end
            end else if (seq == readX) begin
                reading[7:4] <= adcValue[11:8];//if readX sequence, update the reading 
                seq <= eval;//move to evaluation sequence 
                if (count <= 4)//increment the count 
                    count <= count + 1;
            end else if (seq == eval) begin
                //store the user input of joystick in position according to decision 
                case(count)
                    1:position[3:0]<=decision;
                    2:position[7:4]<=decision;
                    3:position[11:8]<=decision;
                    4:position[15:12]<=decision;
                endcase
                seq <= do_none;//move to idel sequence and wait for a button input 
            end
            else if(seq_pass) begin
                pass <= 1;//else if the input sequence is matched, set output pass to be high 
                fail <= 0;//reset fail 
                count <= 0;//reste count 
            end else if(count == 4) begin
                fail <= 1;//else if there are 4 user inputs, user inputed the wrong sequence 
                count <= 0;//set the fail to high  
                position <= 0;//reset the position 
            end
        end
    end

    always_comb begin
        pass_seq = {`UP,`DOWN,`DOWN,`LEFT};//set the pass sequence 
        if (pass_seq == position) begin
            seq_pass = 1;//if the user input matches, seq_pass is 1 
        end else begin
            seq_pass = 0;//else seq_pass is zero 
        end

        //decide the user input according to the reading
        if(reading[3:0]==0&&reading[7:4]!=0&&reading[7:4]!=4'hc) begin
            decision = `UP;
        end else if(reading[3:0]==4'hc&&reading[7:4]!=0&&reading[7:4]!=4'hc) begin
            decision = `DOWN;
        end else if (reading[7:4]==0&&reading[3:0]!=0&&reading[3:0]!=4'hc) begin
            decision = `LEFT;
        end else if (reading[7:4]==4'hc&&reading[3:0]!=0&&reading[3:0]!=4'hc) begin
            decision = `RIGHT;
        end else begin
            decision = `MID;
        end

        case( digit )//assin the display info to the position of joystick 
            3 : displayNum = position[15:12];
            2 : displayNum = position[11:8] ;
            1 : displayNum = position[7:4] ;
            0 : displayNum = position[3:0] ;
		default: 
            displayNum = 'hf ; 
        endcase

        ct =  1'b1 << digit;
    end
    
    always_ff @(posedge clk) begin
        
    // only switch to next digit when count rolls over for crisp display
	    delayCnt <= delayCnt + 1'b1;  
	    if (delayCnt == 0)
		    if (digit >= 3)
			    digit <= '0;
		    else
			    digit <= digit + 1'b1 ;
	end
	

endmodule

