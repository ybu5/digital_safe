// ELEX 7660 202010 Final Project 
// Yanming Bu 2020/4/7
// This is the main module for the digital save
// to unlock the save, user needs to input correct joystcik sequence and correct pincode 
// to lock the save, press any key on the keybord 
`define OPEN 135//servo poen position angle in degree
module digital_save(
    output logic [3:0] kpc,  // column select, active-low
    (* altera_attribute = "-name WEAK_PULL_UP_RESISTOR ON" *)
    input logic  [3:0] kpr,  // rows, active-low w/ pull-ups
	output logic [7:0] leds, // active-low LED segments 
    output logic [3:0] ct,   // " digit enables
    input logic  reset_n, CLOCK_50,
    output logic [7:0] LED, //Leds on fpga for quick debugging 
    output logic PWM_signal,//drive the servo 
    output logic [2:0] indicator,//led indicators 
    output ADC_CONVST, ADC_SCK, ADC_SDI,
    input ADC_SDO
);
    logic [3:0] digit_kpc, joy_kpc;//kpc for joystick stage and pincode stage 
    logic [7:0] digit_leds, joy_leds, kpNum_main;//leds from joystick, pincode, and main 
    logic [3:0] digit_ct, joy_ct;//ct from joystick and pincode 
    logic digit_pass, digit_fail, digit_reset;//varies outputs and inputs for pincode stage 
    logic joy_pass, joy_fail, joy_reset;//varies output and inouts for joystick stage 
    enum{joy_stick, transition, pin_code,unlock} seq;//sequence in main 
    logic [7:0] angle;//servo position 
    logic kphit_state, kphit_pre, kphit_debounce;//kphit stage 

    pll pll0 ( .inclk0(CLOCK_50), .c0(clk) ) ;//pll module to div the clk 
    //modules to drive the servo, debounce the keypad input, check pincode input, and check joystick inputs 
    servo_driver servo_driver_0 (.clk,.reset_n,.angle_pos(angle),.signal(PWM_signal));
    debouncedInput debouncedInput_0 (.rawInput(kphit),.debouncedInput(kphit_debounce),.clk(clk),.reset_n);
    digit_seq digit_seq_0 (.kpc(digit_kpc),.kpr,.leds(digit_leds),.ct(digit_ct),.reset_n(digit_reset),.clk,.pass(digit_pass),.fail(digit_fail));
    joystick_seq joystick_seq_0 (.kpc(joy_kpc),.kpr,.leds(joy_leds),.ct(joy_ct),.pass(joy_pass),.fail(joy_fail),.clk,.reset_n(joy_reset),.ADC_SDO,.ADC_CONVST,.ADC_SCK,.ADC_SDI);
    kpdecode kpdecode_main (.kphit,.num(kpNum_main), .kpr, .kpc(main_kpc));
    
    always_ff @(posedge clk, negedge reset_n) begin
        if(~reset_n) begin
            digit_reset <= 0;//hold reset for pincode stage 
            joy_reset <= 0;//hold reset for joystick stage 
            seq <= joy_stick;//set the seqence to check joystick 
            indicator <=3'b100;//red LED on, the rest to be off
        end else begin
            //store the different state of kphit 
            kphit_state <= kphit_debounce;
            kphit_pre <= kphit_state;
            //state mashine for the sequence 
            if(seq==joy_stick) begin//if it's joystick 
                joy_reset <= 1;//release the reset for joystick 
                indicator <= 3'b100;//make sure the indicator is red on, greens off
                if(joy_pass)begin//if joystick passes, move to transition
                    seq <= transition;
                    indicator <= 3'b101;//one green LED on 
                end
            end else if(seq==transition) begin
                if(kphit_state == 1&&kphit_pre==0&&kpNum_main!=4'hc)
                    seq <= pin_code;//wait for user to press any key other than c, and move to pincode 
            end
            else if(seq==pin_code) begin
                digit_reset <= 1;//release the reset for pincode stage 
                joy_reset <= 0;//hole reset for joystick 
                if(digit_pass) begin//if digit_pass is 1 then move to unlock
                    seq <= unlock;
                    indicator <= 3'b011;//redLED off, two green LED on 
                end
            end else if(seq==unlock) begin
                if(kphit_state == 1&&kphit_pre==0&&kpNum_main!=4'hc)
                    seq <= joy_stick;//wait for user to press any key other than c, and move back to joystick 
                    digit_reset <= 0;//hold reset for pincode stage 
            end
        end
    end

    always_comb begin
        LED[7:0] = indicator;//assign indicator to LED on fpga
        case (seq)
            joy_stick : begin//if seq is joystick 
                angle = 0;//servo in angle of 0 degree
                ct = joy_ct;//joystcuk module controls the 7-segment, keypad 
                leds = joy_leds; 
                kpc = joy_kpc;
            end
            pin_code : begin// if seq is pin_code 
                angle = 0;//servo in angle of 0 degree 
                ct = digit_ct;//digit module controls 7-segment, keypad 
                leds = digit_leds;
                kpc = digit_kpc;
            end
            unlock : begin//if seq us unlock 
                angle = `OPEN;//servo in open position 
                ct = digit_ct;//digit module controls 7-segment
                leds = digit_leds;
                kpc = main_kpc;//main controls the keypad 
            end
            transition : begin//if seq in transition 
                angle = 0;//servo in anagle of 0 degree
                ct = digit_ct;//digit module controls 7-segment
                leds = digit_leds;
                kpc = main_kpc;//main controls the keypad 
            end
            default: begin//else 
                angle = 0;//servo in angle of 0 
                ct = digit_ct;//digit controls 7-segment and keypad 
                leds = digit_leds;
                kpc = digit_kpc;
            end
        endcase
    end
endmodule

module pll ( inclk0, c0);

        input     inclk0;
        output    c0;

        wire [0:0] sub_wire2 = 1'h0;
        wire [4:0] sub_wire3;
        wire  sub_wire0 = inclk0;
        wire [1:0] sub_wire1 = {sub_wire2, sub_wire0};
        wire [0:0] sub_wire4 = sub_wire3[0:0];
        wire  c0 = sub_wire4;

        altpll altpll_component ( .inclk (sub_wire1), .clk
          (sub_wire3), .activeclock (), .areset (1'b0), .clkbad
          (), .clkena ({6{1'b1}}), .clkloss (), .clkswitch
          (1'b0), .configupdate (1'b0), .enable0 (), .enable1 (),
          .extclk (), .extclkena ({4{1'b1}}), .fbin (1'b1),
          .fbmimicbidir (), .fbout (), .fref (), .icdrclk (),
          .locked (), .pfdena (1'b1), .phasecounterselect
          ({4{1'b1}}), .phasedone (), .phasestep (1'b1),
          .phaseupdown (1'b1), .pllena (1'b1), .scanaclr (1'b0),
          .scanclk (1'b0), .scanclkena (1'b1), .scandata (1'b0),
          .scandataout (), .scandone (), .scanread (1'b0),
          .scanwrite (1'b0), .sclkout0 (), .sclkout1 (),
          .vcooverrange (), .vcounderrange ());

        defparam
                altpll_component.bandwidth_type = "AUTO",
                altpll_component.clk0_divide_by = 25000,
                altpll_component.clk0_duty_cycle = 50,
                altpll_component.clk0_multiply_by = 1,
                altpll_component.clk0_phase_shift = "0",
                altpll_component.compensate_clock = "CLK0",
                altpll_component.inclk0_input_frequency = 20000,
                altpll_component.intended_device_family = "Cyclone IV E",
                altpll_component.lpm_hint = "CBX_MODULE_PREFIX=lab1clk",
                altpll_component.lpm_type = "altpll",
                altpll_component.operation_mode = "NORMAL",
                altpll_component.pll_type = "AUTO",
                altpll_component.port_activeclock = "PORT_UNUSED",
                altpll_component.port_areset = "PORT_UNUSED",
                altpll_component.port_clkbad0 = "PORT_UNUSED",
                altpll_component.port_clkbad1 = "PORT_UNUSED",
                altpll_component.port_clkloss = "PORT_UNUSED",
                altpll_component.port_clkswitch = "PORT_UNUSED",
                altpll_component.port_configupdate = "PORT_UNUSED",
                altpll_component.port_fbin = "PORT_UNUSED",
                altpll_component.port_inclk0 = "PORT_USED",
                altpll_component.port_inclk1 = "PORT_UNUSED",
                altpll_component.port_locked = "PORT_UNUSED",
                altpll_component.port_pfdena = "PORT_UNUSED",
                altpll_component.port_phasecounterselect = "PORT_UNUSED",
                altpll_component.port_phasedone = "PORT_UNUSED",
                altpll_component.port_phasestep = "PORT_UNUSED",
                altpll_component.port_phaseupdown = "PORT_UNUSED",
                altpll_component.port_pllena = "PORT_UNUSED",
                altpll_component.port_scanaclr = "PORT_UNUSED",
                altpll_component.port_scanclk = "PORT_UNUSED",
                altpll_component.port_scanclkena = "PORT_UNUSED",
                altpll_component.port_scandata = "PORT_UNUSED",
                altpll_component.port_scandataout = "PORT_UNUSED",
                altpll_component.port_scandone = "PORT_UNUSED",
                altpll_component.port_scanread = "PORT_UNUSED",
                altpll_component.port_scanwrite = "PORT_UNUSED",
                altpll_component.port_clk0 = "PORT_USED",
                altpll_component.port_clk1 = "PORT_UNUSED",
                altpll_component.port_clk2 = "PORT_UNUSED",
                altpll_component.port_clk3 = "PORT_UNUSED",
                altpll_component.port_clk4 = "PORT_UNUSED",
                altpll_component.port_clk5 = "PORT_UNUSED",
                altpll_component.port_clkena0 = "PORT_UNUSED",
                altpll_component.port_clkena1 = "PORT_UNUSED",
                altpll_component.port_clkena2 = "PORT_UNUSED",
                altpll_component.port_clkena3 = "PORT_UNUSED",
                altpll_component.port_clkena4 = "PORT_UNUSED",
                altpll_component.port_clkena5 = "PORT_UNUSED",
                altpll_component.port_extclk0 = "PORT_UNUSED",
                altpll_component.port_extclk1 = "PORT_UNUSED",
                altpll_component.port_extclk2 = "PORT_UNUSED",
                altpll_component.port_extclk3 = "PORT_UNUSED",
                altpll_component.width_clock = 5;


endmodule