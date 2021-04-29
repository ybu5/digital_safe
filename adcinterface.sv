// ELEX 7660 202010 Lab 3
// An ADC interface module to interface with the Ltc2308 ADC  
// Yanming Bu 2020/1/28

`define CYCLE_WHAT 12 //define a constant for 12 clock cycles 
module adcinterface(
    input logic clk, reset_n,
    input logic [2:0] chan,
    output logic [11:0] result,

    output logic ADC_CONVST, ADC_SCK, ADC_SDI,
    input logic ADC_SDO 
);
    //create enum for the four states 
    enum{conv1, conv2, sck, pre_conv} state, next_state;
    
    logic [4:0] next_count = 0;
    logic [4:0] count = 1;
    logic [11:0] config_num;
    logic [11:0] pre_result = 0;
    
    // controls what is the next state and how many clk cycles that state will stay  
    always_comb begin
        next_count = count - 1;
        next_state = state;
        if (next_count ==0) begin
            // when next_count is zero, here is the state cycle 
            //conv1 -> conv2 -> sck -> pre_conv -> conv1
            case (state)
                conv1: next_state = conv2;
                conv2: next_state = sck;
                sck : next_state = pre_conv;
                pre_conv: next_state = conv1;
            endcase
            //stay at sck for 12 clock cycles  
            if (next_state == sck) begin
                next_count = `CYCLE_WHAT;
            end 
            //stay at pre_conv for 2 clock cycles 
            else if (next_state == pre_conv) begin
                next_count = 2;
            end
            //else stay at conv1 and conv2 for 1 clock cycles 
            else begin
                next_count = 1;
            end
        end
    end

    //clock the next state into the state, and change the count value
    //clock the pre-result into result 
    always_ff @(negedge clk, negedge reset_n) begin
        if (~reset_n) begin
            state <= pre_conv;
            count <= 1;
            result <= 0;
        end else begin
            state<= next_state;
            count <= next_count;
            if(next_state == pre_conv)
                result <= pre_result;
            else
                result <= result;
        end
    end
    //set ADC_SCK to follow the clock when it's on sck state, otherwise set it to zero
    assign ADC_SCK = (state==sck)?clk:1'b0;

    //according to different states, sets ADC_CONVST
    always_comb begin
        case (state)
            //at the pre_conv state, 
            //ADC_CONVST stays low 
            pre_conv: begin 
                ADC_CONVST = 0;
            end
            //at conv1 state.
            //ADC_CONVST stays high
            conv1: begin 
                ADC_CONVST = 1;
            end
            //at con2 state, 
            //ADC_CONVST stays low 
            conv2: begin 
                ADC_CONVST = 0;
            end
            //at sck state,
            //ADC_SCK stays low
            sck: begin 
                ADC_CONVST = 0;
            end
        endcase
    end

    //accoding to chan, select different channel for ADC to sample 
    always_comb begin
        case (chan)
            0: config_num = 12'b100010000000;//channel 0 
            1: config_num = 12'b110010000000;//channel 1
            2: config_num = 12'b100110000000;//channel 2
            3: config_num = 12'b110110000000;//channel 3
            4: config_num = 12'b101010000000;//channel 4
            5: config_num = 12'b111010000000;//channel 5
            6: config_num = 12'b101110000000;//channel 6
            7: config_num = 12'b111110000000;//channel 7
            default: begin
                
            end
        endcase
    end

    //flip flop triggers at the falling edge of the clock, active low reset  
    //shifting config_num out from ADC_SDI and getting ADC_SDO into output result 
    always_ff @(negedge clk, negedge reset_n) begin
        if (~reset_n) begin
            pre_result <= 0;//reset
            ADC_SDI <=0; 
        end else begin
            //the conv2 state, before ADC_SCK start clocking 
            //set out the most significan bit of the config_num 
            //receive the most significan bit from previous sample 
            if (state == conv2) begin
                ADC_SDI <= config_num[11];
                pre_result[11] <= ADC_SDO;
            end
            //in the sck state 
            //send out the rest of config_num 
            //receive the rest of the sample data 
            else if (state == sck) begin
                ADC_SDI <= config_num[next_count - 1];
                pre_result[count - 1] <= ADC_SDO;
            end
            //else set out 0 
            else begin
                ADC_SDI <=0;
            end
        end
        
    end
    
endmodule