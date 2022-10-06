module divider #(parameter n = 25) (clk, clk_div);
    // parameter n = 25;
    input clk;
    output clk_div;
    reg [n-1:0]num = 0;
    wire [n-1:0]next_num;
    
    always @(posedge clk) begin
        num <= next_num;
    end
    
    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule

module top(
    input clk,
    input rst,  //pb
    input enter,//pb
    input start_play,//pb
    input pause,
    input echo,
    inout PS2_DATA,
    inout PS2_CLK,
    output trig,
    output reg [6:0] display,
    output reg [3:0] digit,
    output reg [15:0] led
    );
/*///////////////////////////////////////////////////////////////////////////////////*/
    wire new_clk_13;
    wire new_clk_16;
    wire new_clk_24;
    wire new_clk_27;
    wire new_clk_26;
    wire new_clk_23;
    divider #(.n(13)) clkdiv_13(clk, new_clk_13);
    divider #(.n(16)) clkdiv_16(clk, new_clk_16);
    divider #(.n(24)) clkdiv_24(clk, new_clk_24);
    divider #(.n(27)) clkdiv_27(clk, new_clk_27);
    divider #(.n(26)) clkdiv_26(clk, new_clk_26);
    divider #(.n(23)) clkdiv_23(clk, new_clk_23);

/*///////////////////////////////////////////////////////////////////////////////////*/
    wire tmp_rst, new_rst;
    wire tmp_enter, new_enter;
    wire tmp_start_play, new_start_play;
    wire tmp_newgame, new_newgame;
    debounce db_rst(tmp_rst, rst, new_clk_16);
    onepulse op_rst(tmp_rst, new_clk_27, new_rst);
    debounce db_enter(tmp_enter, enter, new_clk_16);
    onepulse op_enter(tmp_enter, new_clk_27, new_enter);
    debounce db_start_play(tmp_start_play, start_play, new_clk_16);
    onepulse op_start_play(tmp_start_play, new_clk_27, new_start_play);
    debounce db_newgame(tmp_newgame, newgame, new_clk_16);
    onepulse op_newgame(tmp_newgame, new_clk_27, new_newgame);
/*///////////////////////////////////////////////////////////////////////////////////*/
    wire clk__1m;
    wire [19:0] dis;
    div b1(clk, clk__1m);
    TrigSignal a1(clk, new_rst, trig);
    PosCounter a2(clk__1m, new_rst, echo, dis);
    reg [5:0] sc_cnt1, sc_cnt2;
/*///////////////////////////////////////////////////////////////////////////////////*/
    parameter [8:0] KEY_CODES [0:2] = {
		9'b0_0110_1001, // 1 => 69
		9'b0_0111_0010, // 2 => 72
		9'b0_0111_1010 // 3 => 7A
	};
	
	reg [3:0] key_num;
    //reg [3:0] num;
	reg [9:0] last_key;
	
	wire [511:0] key_down;
	wire [8:0] last_change;
	wire been_ready;
		
	KeyboardDecoder key_de (
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);

    always @ (*) begin
		case (last_change)
			KEY_CODES[00] : key_num = 4'b0001;
			KEY_CODES[01] : key_num = 4'b0010;
			KEY_CODES[02] : key_num = 4'b0011;
			default		  : key_num = 4'b1111;
		endcase
	end
/*///////////////////////////////////////////////////////////////////////////////////*/
    parameter [2:0] ready = 3'b000;
    parameter [2:0] chse_second = 3'b001;
    parameter [2:0] cnt_down = 3'b010;
    parameter [2:0] play = 3'b011;
    parameter [2:0] endgame = 3'b100;
    reg [5:0] num1, num2, num3, num4, num, num1_next, num2_next, num3_next, num4_next, keyin_num;
    reg [3:0] cnt, endgame_cnt, cntdown;
    wire [2:0] div, rem;  //divider  reminder
    reg [2:0] flag_clk;
    reg [2:0] state, state_next;
    reg standard, std;
    //wire [5:0] score;
    

/*///////////////////////////////////////////////////////////////////////////////////*/
    assign div = cnt / 4;
    assign rem = cnt % 4;

    always @(posedge new_clk_13) begin
        flag_clk <= flag_clk + 1;
    end

    always @(posedge new_clk_24) begin  //for state ready
        if(cnt >= 4'd15) begin
            cnt <= 4'd0;
        end
        else begin
            cnt <= cnt + 1;
        end
    end

    always @(posedge new_clk_26) begin  //for state endgame
        if(state==endgame) begin
            if(endgame_cnt>=4'd9) begin
                endgame_cnt <= 4'd9;
            end
            else begin
                endgame_cnt <= endgame_cnt + 1;
            end
        end
        else begin
            endgame_cnt <= 4'd0;
        end
    end
    
    always @(posedge clk or posedge new_rst) begin //for state chse_second
        if(new_rst) begin
            keyin_num <= 6'b000001;
        end
        else begin
            if(state==chse_second) begin
                if (been_ready && key_down[last_change] == 1'b1) begin
                    if(key_num!=4'b1111) begin
                        if(key_num==4'b0001) begin
                            keyin_num <= 6'b000001;
                        end
                        else if(key_num==4'b0010) begin
                            keyin_num <= 6'b000010;
                        end
                        else begin
                            keyin_num <= 6'b000011;
                        end
                    end
                end
                else begin
                    keyin_num <= keyin_num;
                end
            end
            else begin
                keyin_num <= keyin_num;
            end
        end
    end

    always @(posedge new_clk_27) begin //for state cnt_down
        if(state==cnt_down) begin
            if(cntdown==4'd4) begin
                cntdown <= 4'd4;
            end
            else begin
                cntdown <= cntdown + 1;
            end
        end
        else begin
            cntdown <= 4'd0;
        end
    end

    //assign score = sc_cnt1*10 + sc_cnt2;
    always @(posedge new_clk_16) begin  // std = 1 / good   std = 0 / suck
        std <= standard;
    end

    always @(*) begin
        if(state==play) begin
            //score = sc_cnt1*10 + sc_cnt2;
            //score = num1*10 + num2;
            if(keyin_num==6'd1) begin
                if(sc_cnt1>6'd0 || sc_cnt2>6'd5) begin
                    standard = 1;
                end
                else begin
                    standard = 0;
                end
            end
            else if(keyin_num==6'd2) begin
                if(sc_cnt1>=6'd1 && sc_cnt2>=6'd0) begin
                    standard = 1;
                end
                else begin
                    standard = 0;
                end
            end
            else begin
                if(sc_cnt1>=6'd2 && sc_cnt2>=6'd0) begin
                    standard = 1;
                end
                else begin
                    standard = 0;
                end
            end
        end
        else begin
            standard = std;
        end
    end

    always @(*) begin  //led
        if(state==endgame) begin
            if(endgame_cnt==4'd1 || endgame_cnt==4'd3 || endgame_cnt==4'd5 || endgame_cnt==4'd7) begin
                led = 16'b1111_1111_1111_1111;
            end
            else begin
                led = 16'b0000_0000_0000_0000;
            end
        end
        else begin
            led = 16'b0000_0000_0000_0000;
        end
    end

    always @(posedge new_clk_23 or posedge new_rst) begin
        if(new_rst) begin
            sc_cnt1 <= 6'b000000;
            sc_cnt2 <= 6'b000000;
        end
        else begin
            if(state==play) begin
                if(dis < 20'd1000 && !pause) begin
                    if(sc_cnt1==6'b001001 && sc_cnt2==6'b001001) begin
                        sc_cnt1 <= sc_cnt1;
                        sc_cnt2 <= sc_cnt2;
                    end
                    else begin
                        if(sc_cnt2==6'b001001) begin
                            if(sc_cnt1==6'b001001) begin
                                sc_cnt1 <= 6'b001001;
                                sc_cnt2 <= 6'b001001;
                            end
                            else begin
                                sc_cnt1 <= sc_cnt1 + 1;
                                sc_cnt2 <= 6'b000000;
                            end
                        end
                        else begin
                            sc_cnt2 <= sc_cnt2 + 1;
                        end
                    end
                end
                else begin
                    sc_cnt1 <= sc_cnt1;
                    sc_cnt2 <= sc_cnt2;
                end
            end
            else begin
                sc_cnt1 <= 6'b000000;
                sc_cnt2 <= 6'b000000;
            end
        end
    end
//---------------------------------------------//
//7-segment
    always @(*) begin
        case(state)
            ready: begin
                case(flag_clk)
                    2'b01: begin
                        if(cnt<4'd8) begin
                            if(div==0) begin
                                num = 6'b010110;
                            end
                            else begin
                                num = 6'b010111;
                            end

                            if(rem==0) begin
                                if(div==0) digit = 4'b0111;
                                else digit = 4'b1110;
                            end
                            else begin
                                digit = 4'b1111;
                            end
                        end
                        else begin
                            num = 6'b001000;
                            if(cnt==4'd8 || cnt==4'd9 || cnt==4'd12 || cnt==4'd13) begin                        
                                digit = 4'b0111;
                            end
                            else begin
                                digit = 4'b1111;
                            end
                        end
                    end
                    2'b10: begin
                        if(cnt<4'd8) begin
                            if(div==0) begin
                                num = 6'b010110;
                            end
                            else begin
                                num = 6'b010111;
                            end

                            if(rem==1) begin
                                if(div==0) digit = 4'b1011;
                                else digit = 4'b1101;
                            end
                            else begin
                                digit = 4'b1111;
                            end
                        end
                        else begin
                            num = 6'b001000;
                            if(cnt==4'd8 || cnt==4'd9 || cnt==4'd12 || cnt==4'd13) begin                        
                                digit = 4'b1011;
                            end
                            else begin
                                digit = 4'b1111;
                            end
                        end
                    end
                    2'b11: begin
                        if(cnt<4'd8) begin
                            if(div==0) begin
                                num = 6'b010110;
                            end
                            else begin
                                num = 6'b010111;
                            end

                            if(rem==2) begin
                                if(div==0) digit = 4'b1101;
                                else digit = 4'b1011;
                            end
                            else begin
                                digit = 4'b1111;
                            end
                        end
                        else begin
                            num = 6'b001000;
                            if(cnt==4'd8 || cnt==4'd9 || cnt==4'd12 || cnt==4'd13) begin                        
                                digit = 4'b1101;
                            end
                            else begin
                                digit = 4'b1111;
                            end
                        end
                    end
                    2'b00: begin
                        if(cnt<4'd8) begin
                            if(div==0) begin
                                num = 6'b010110;
                            end
                            else begin
                                num = 6'b010111;
                            end

                            if(rem==3) begin
                                if(div==0) digit = 4'b1110;
                                else digit = 4'b0111;
                            end
                            else begin
                                digit = 4'b1111;
                            end
                        end
                        else begin
                            num = 6'b001000;
                            if(cnt==4'd8 || cnt==4'd9 || cnt==4'd12 || cnt==4'd13) begin                        
                                digit = 4'b1110;
                            end
                            else begin
                                digit = 4'b1111;
                            end
                        end
                    end
                endcase
            end
            chse_second: begin
                case(flag_clk)
                    2'b01: begin
                        num = num1;
                        digit = 4'b0111;
                    end
                    2'b10: begin
                        num = 6'b000000;
                        digit = 4'b1111;
                    end
                    2'b11: begin
                        num = num3;
                        digit = 4'b1101;
                    end
                    2'b00: begin
                        num = num4;
                        digit = 4'b1110;
                    end
                endcase
            end
            cnt_down: begin
                case(flag_clk)
                    2'b01: begin
                        num = 6'b000000;
                        digit = 4'b1111;
                    end
                    2'b10: begin
                        if(cntdown==0) begin
                            num = 6'b000011;
                            digit = 4'b1011;
                        end
                        else if(cntdown==3) begin
                            num = 6'b001110;
                            digit = 4'b1011;
                        end
                        else begin
                            num = 6'b000000;
                            digit = 4'b1111;
                        end
                    end
                    2'b11: begin
                        if(cntdown==2) begin
                            num = 6'b000000;
                            digit = 4'b1111;
                        end
                        else if(cntdown==3) begin
                            num = 6'b010001;
                            digit = 4'b1101;
                        end
                        else begin
                            num = 6'b000010;
                            digit = 4'b1101;
                        end
                    end
                    2'b00: begin
                        if(cntdown==3) begin
                            num = 6'b000000;
                            digit = 4'b1111;
                        end
                        else begin
                            num = 6'b000001;
                            digit = 4'b1110;
                        end
                    end
                endcase
            end
            play: begin
                case(flag_clk)
                    2'b01: begin
                        if(sc_cnt1>0) begin
                            num = sc_cnt1;
                            digit = 4'b0111;
                        end
                        else begin
                            num = 6'b000000;
                            digit = 4'b1111;
                        end
                    end
                    2'b10: begin
                        num = sc_cnt2;
                        digit = 4'b1011;
                    end
                    2'b11: begin
                        num = num3;
                        digit = 4'b1101;
                    end
                    2'b00: begin
                        num = num4;
                        digit = 4'b1110;
                    end
                endcase
            end
            endgame: begin
                case(flag_clk)
                    2'b01: begin
                        num = num1;
                        if(endgame_cnt==4'd1 || endgame_cnt==4'd3 || endgame_cnt==4'd5 || endgame_cnt==4'd7) begin
                            digit = 4'b0111;
                        end
                        else begin
                            digit = 4'b1111;
                        end
                    end
                    2'b10: begin
                        num = num2;
                        if(endgame_cnt==4'd1 || endgame_cnt==4'd3 || endgame_cnt==4'd5 || endgame_cnt==4'd7) begin
                            digit = 4'b1011;
                        end
                        else begin
                            digit = 4'b1111;
                        end
                    end
                    2'b11: begin
                        num = num3;
                        if(endgame_cnt==4'd1 || endgame_cnt==4'd3 || endgame_cnt==4'd5 || endgame_cnt==4'd7) begin
                            digit = 4'b1101;
                        end
                        else begin
                            digit = 4'b1111;
                        end
                    end
                    2'b00: begin
                        num = num4;
                        if(endgame_cnt==4'd1 || endgame_cnt==4'd3 || endgame_cnt==4'd5 || endgame_cnt==4'd7) begin
                            digit = 4'b1110;
                        end
                        else begin
                            digit = 4'b1111;
                        end
                    end
                endcase
            end
            default: begin
                num = 6'b000001;
                digit = 4'b0000;
            end
        endcase
    end

    always @(*) begin
        case(num)
            6'b000000: begin
                display = 7'b1000000;
            end
            6'b000001: begin
                display = 7'b1111001;
            end
            6'b000010: begin
                display = 7'b0100100;
            end
            6'b000011: begin
                display = 7'b0110000;
            end
            6'b000100: begin
                display = 7'b0011001;
            end
            6'b000101: begin
                display = 7'b0010010;
            end
            6'b000110: begin
                display = 7'b0000010;
            end
            6'b000111: begin
                display = 7'b1011000;
            end
            6'b001000: begin
                display = 7'b0000000;
            end
            6'b001001: begin
                display = 7'b0011000;
            end
            6'b001010: begin 
                display = 7'b0100000; //A
            end
            6'b001011: begin
                display = 7'b0100111; //C
            end
            6'b001100: begin
                display = 7'b0100001; //D
            end
            6'b001101: begin
                display = 7'b0000110; //E
            end
            6'b001110: begin
                display = 7'b1000010; //G
            end
            6'b001111: begin
                display = 7'b0001011; //H
            end
            6'b010000: begin
                display = 7'b0001010; //K
            end
            6'b010001: begin
                display = 7'b0100011; //O
            end
            6'b010010: begin
                display = 7'b0101111; //R
            end
            6'b010011: begin
                display = 7'b1010010; //S
            end
            6'b010100: begin
                display = 7'b1100011; //U
            end
            6'b010101: begin
                display = 7'b0010001; //Y
            end
            6'b010110: begin //22
                display = 7'b1100011; //down arrow
            end
            6'b010111: begin //23
                display = 7'b1011100; //up arrow
            end
            default : begin
                display = 7'b0000000;
            end
        endcase
    end

//---------------------------------------------//
//state control
    always @(posedge new_clk_26 or posedge new_rst) begin
        if(new_rst) begin
            state <= ready;
            num1 <= 6'b000000;
            num2 <= 6'b000000;
            num3 <= 6'b000000;
            num4 <= 6'b000000;
        end
        else begin
            state <= state_next;
            num1 <= num1_next;
            num2 <= num2_next;
            num3 <= num3_next;
            num4 <= num4_next;
        end
    end

    always @(*) begin
        case(state)
            ready: begin
                if(new_enter) begin
                    state_next = chse_second;
                end
                else begin
                    state_next = ready;
                end
                num1_next = 6'b000001;
                num2_next = 6'b000000;
                num3_next = 6'b000011;
                num4_next = 6'b000000;
            end
            chse_second: begin
                if(start_play) begin
                    state_next = cnt_down;
                    num1_next = 6'b000000;
                    num2_next = 6'b000011;
                    num3_next = 6'b000010;
                    num4_next = 6'b000001;
                end
                else begin
                    state_next = chse_second;
                    num1_next = keyin_num;
                    num2_next = 6'b000000;
                    num4_next = 6'b000000;
                    if(keyin_num==6'd1) begin
                        num3_next = 6'b000011;
                    end
                    else if(keyin_num==6'd2) begin
                        num3_next = 6'b000110;
                    end
                    else begin
                        num3_next = 6'b001001;
                    end
                end
            end
            cnt_down: begin
                if(cntdown==4) begin
                    state_next = play;
                    num1_next = 6'b000000;
                    num2_next = 6'b000000;
                    num4_next = 6'b000000;
                    if(keyin_num==6'b000001) begin
                        num3_next = 6'b000011;
                    end
                    else if(keyin_num==6'b000010) begin
                        num3_next = 6'b000110;
                    end
                    else begin
                        num3_next = 6'b001001;
                    end
                end
                else begin
                    state_next = cnt_down;
                    num1_next = 6'b000000;
                    num2_next = 6'b000000;
                    num3_next = 6'b000000;
                    num4_next = 6'b000000;
                end
            end
            play: begin
                if(num3==6'b000000 && num4==6'b000000) begin
                    state_next = endgame;
                    if(std) begin
                        num1_next = 6'b001110;
                        num2_next = 6'b010001;
                        num3_next = 6'b010001;
                        num4_next = 6'b001100;
                    end
                    else begin
                        num1_next = 6'b010011;
                        num2_next = 6'b010100;
                        num3_next = 6'b001011;
                        num4_next = 6'b010000;
                    end
                end
                else begin
                    state_next = play;
                    num1_next = 6'b000000;
                    num2_next = 6'b000000;
                    if(pause) begin
                        num3_next = num3;
                        num4_next = num4;
                    end
                    else begin
                        if(num4==6'd000000) begin
                            if(num3==0) begin
                                num3_next = 6'b000000;
                                num4_next = 6'b000000;
                            end
                            else begin
                                num3_next = num3 - 6'b000001;
                                num4_next = 6'b001001;
                            end
                        end
                        else begin
                            num4_next = num4 - 6'b000001;
                            num3_next = num3;
                        end
                    end
                    // if(num4==6'd000000) begin
                    //     if(num3==0) begin
                    //         num3_next = 6'b000000;
                    //         num4_next = 6'b000000;
                    //     end
                    //     else begin
                    //         num3_next = num3 - 6'b000001;
                    //         num4_next = 6'b001001;
                    //     end
                    // end
                    // else begin
                    //     num4_next = num4 - 6'b000001;
                    //     num3_next = num3;
                    // end
                end
            end
            endgame: begin
                if(endgame_cnt==4'd9) begin
                    state_next = ready;
                    num1_next = 6'b000000;
                    num2_next = 6'b000000;
                    num3_next = 6'b000000;
                    num4_next = 6'b000000;
                end
                else begin
                    state_next = endgame;
                    num1_next = num1;
                    num2_next = num2;
                    num3_next = num3;
                    num4_next = num4;
                end
            end
        endcase
    end

endmodule


module debounce (pb_debounced, pb, clk);
    output pb_debounced;
    input pb;
    input clk;
    
    reg [3:0] shift_reg;
    
    always @(posedge clk) begin
        shift_reg[3:1] <= shift_reg[2:0];
        shift_reg[0] <= pb;
    end
    
    assign pb_debounced = ((shift_reg == 4'b1111) ? 1'b1 : 1'b0);
    
endmodule

module onepulse (pb_debounced, clk, pb_1pulse);
    input pb_debounced;
    input clk;
    output pb_1pulse;
    
    reg pb_1pulse;
    reg pb_debounced_delay;
    
    always @(posedge clk) begin
        if(pb_debounced == 1'b1 & pb_debounced_delay == 1'b0)
            pb_1pulse <= 1'b1;
        else
            pb_1pulse <= 1'b0;
            
        pb_debounced_delay <= pb_debounced;
    end
endmodule

module KeyboardDecoder(
	output reg [511:0] key_down,
	output wire [8:0] last_change,
	output reg key_valid,
	inout wire PS2_DATA,
	inout wire PS2_CLK,
	input wire rst,
	input wire clk
    );
    
    parameter [1:0] INIT			= 2'b00;
    parameter [1:0] WAIT_FOR_SIGNAL = 2'b01;
    parameter [1:0] GET_SIGNAL_DOWN = 2'b10;
    parameter [1:0] WAIT_RELEASE    = 2'b11;
    
	parameter [7:0] IS_INIT			= 8'hAA;
    parameter [7:0] IS_EXTEND		= 8'hE0;
    parameter [7:0] IS_BREAK		= 8'hF0;
    
    reg [9:0] key;		// key = {been_extend, been_break, key_in}
    reg [1:0] state;
    reg been_ready, been_extend, been_break;
    
    wire [7:0] key_in;
    wire is_extend;
    wire is_break;
    wire valid;
    wire err;
    
    wire [511:0] key_decode = 1 << last_change;
    assign last_change = {key[9], key[7:0]};
    
    KeyboardCtrl_0 inst (
		.key_in(key_in),
		.is_extend(is_extend),
		.is_break(is_break),
		.valid(valid),
		.err(err),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);
	
	OnePulse_key op (
		.signal_single_pulse(pulse_been_ready),
		.signal(been_ready),
		.clock(clk)
	);
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		state <= INIT;
    		been_ready  <= 1'b0;
    		been_extend <= 1'b0;
    		been_break  <= 1'b0;
    		key <= 10'b0_0_0000_0000;
    	end else begin
    		state <= state;
			been_ready  <= been_ready;
			been_extend <= (is_extend) ? 1'b1 : been_extend;
			been_break  <= (is_break ) ? 1'b1 : been_break;
			key <= key;
    		case (state)
    			INIT : begin
    					if (key_in == IS_INIT) begin
    						state <= WAIT_FOR_SIGNAL;
    						been_ready  <= 1'b0;
							been_extend <= 1'b0;
							been_break  <= 1'b0;
							key <= 10'b0_0_0000_0000;
    					end else begin
    						state <= INIT;
    					end
    				end
    			WAIT_FOR_SIGNAL : begin
    					if (valid == 0) begin
    						state <= WAIT_FOR_SIGNAL;
    						been_ready <= 1'b0;
    					end else begin
    						state <= GET_SIGNAL_DOWN;
    					end
    				end
    			GET_SIGNAL_DOWN : begin
						state <= WAIT_RELEASE;
						key <= {been_extend, been_break, key_in};
						been_ready  <= 1'b1;
    				end
    			WAIT_RELEASE : begin
    					if (valid == 1) begin
    						state <= WAIT_RELEASE;
    					end else begin
    						state <= WAIT_FOR_SIGNAL;
    						been_extend <= 1'b0;
    						been_break  <= 1'b0;
    					end
    				end
    			default : begin
    					state <= INIT;
						been_ready  <= 1'b0;
						been_extend <= 1'b0;
						been_break  <= 1'b0;
						key <= 10'b0_0_0000_0000;
    				end
    		endcase
    	end
    end
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		key_valid <= 1'b0;
    		key_down <= 511'b0;
    	end else if (key_decode[last_change] && pulse_been_ready) begin
    		key_valid <= 1'b1;
    		if (key[8] == 0) begin
    			key_down <= key_down | key_decode;
    		end else begin
    			key_down <= key_down & (~key_decode);
    		end
    	end else begin
    		key_valid <= 1'b0;
			key_down <= key_down;
    	end
    end

endmodule


module OnePulse_key (
	output reg signal_single_pulse,
	input wire signal,
	input wire clock
	);
	
	reg signal_delay;

	always @(posedge clock) begin
		if (signal == 1'b1 & signal_delay == 1'b0)
		  signal_single_pulse <= 1'b1;
		else
		  signal_single_pulse <= 1'b0;

		signal_delay <= signal;
	end
endmodule

module PosCounter(clk, rst, echo, distance_count); 
    input clk, rst, echo;
    output[19:0] distance_count;

    parameter S0 = 2'b00;
    parameter S1 = 2'b01; 
    parameter S2 = 2'b10;
    
    wire start, finish;
    reg[1:0] curr_state, next_state;
    reg echo_reg1, echo_reg2;
    reg[19:0] count, distance_register;
    wire[19:0] distance_count; 

    always@(posedge clk) begin
        if(rst) begin
            echo_reg1 <= 0;
            echo_reg2 <= 0;
            count <= 0;
            distance_register  <= 0;
            curr_state <= S0;
        end
        else begin
            echo_reg1 <= echo;   
            echo_reg2 <= echo_reg1; 
            case(curr_state)
                S0:begin
                    if (start) curr_state <= next_state; //S1
                    else count <= 0;
                end
                S1:begin
                    if (finish) curr_state <= next_state; //S2
                    else count <= count + 1;
                end
                S2:begin
                    distance_register <= count;
                    count <= 0;
                    curr_state <= next_state; //S0
                end
            endcase
        end
    end

    always @(*) begin
        case(curr_state)
            S0:next_state = S1;
            S1:next_state = S2;
            S2:next_state = S0;
        endcase
    end

    assign distance_count = distance_register  * 100 / 58; 
    assign start = echo_reg1 & ~echo_reg2;  
    assign finish = ~echo_reg1 & echo_reg2; 
endmodule

module TrigSignal(clk, rst, trig);
    input clk, rst;
    output trig;

    reg trig, next_trig;
    reg[23:0] count, next_count;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count <= 0;
            trig <= 0;
        end
        else begin
            count <= next_count;
            trig <= next_trig;
        end
    end

    always @(*) begin
        next_trig = trig;
        next_count = count + 1;
        if(count == 999)
            next_trig = 0;
        else if(count == 24'd9999999) begin
            next_trig = 1;
            next_count = 0;
        end
    end
endmodule

module div(clk ,out_clk);
    input clk;
    output reg out_clk;
    reg clkout;
    reg [6:0]cnt;
    
    always @(posedge clk) begin   
        if(cnt < 7'd50) begin
            cnt <= cnt + 1'b1;
            out_clk <= 1'b1;
        end 
        else if(cnt < 7'd100) begin
	        cnt <= cnt + 1'b1;
	        out_clk <= 1'b0;
        end
        else if(cnt == 7'd100) begin
            cnt <= 0;
            out_clk <= 1'b1;
        end
    end
endmodule