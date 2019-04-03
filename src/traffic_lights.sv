module traffic_lights #(
  parameter logic [15:0] BLINK_HALF_PERIOD   = 500,
  parameter logic [15:0] GREEN_BLINKS_NUM    = 4,
  parameter logic [15:0] RED_YELLOW_TIME     = 3000,
  parameter logic [15:0] RED_TIME_DEFAULT    = 10000,
  parameter logic [15:0] YELLOW_TIME_DEFAULT = 3000,
  parameter logic [15:0] GREEN_TIME_DEFAULT  = 8000
)(
  input               clk_i,
  input               srst_i,
  
  input        [2:0]  cmd_type_i,
  input               cmd_valid_i,
  input        [15:0] cmd_data_i,
  
  output logic        red_o,
  output logic        yellow_o,
  output logic        green_o
);


// cmd_types
enum logic [2:0] {TURN_ON_CMD         = 3'd0,
                  TURN_OFF_CMD        = 3'd1,
                  SET_UNC_CMD         = 3'd2,
                  SET_GREEN_TIME_CMD  = 3'd3,
                  SET_RED_TIME_CMD    = 3'd4,
                  SET_YELLOW_TIME_CMD = 3'd5} cmd_type;


// states
enum logic [4:0] {RED_S             = 5'b00_100,
                  RED_YELLOW_S      = 5'b00_110,
                  GREEN_S           = 5'b00_001,
                  GREEN_BLINK_OFF_S = 5'b10_000,
                  GREEN_BLINK_ON_S  = 5'b01_001,
                  YELLOW_S          = 5'b00_010,
                  TURN_OFF_S        = 5'b00_000,
                  UNC_ON_S          = 5'b01_010,
                  UNC_OFF_S         = 5'b11_000} state, next_state;
                
// outputs
assign {red_o, yellow_o, green_o} = state[2:0];

// wrk_en
localparam logic [16:0] DELIMITER = 17'd100000;
//localparam logic [16:0] DELIMITER = 17'd10;

logic        wrk_en;
logic [16:0] wrk_cntr;


// registers
logic [15:0] cntr;
logic [15:0] unc_cntr;
logic [15:0] blink_cntr;
logic        cntr_done;
logic        blink_done;

logic [15:0] red_time;
logic [15:0] yellow_time;
logic [15:0] green_time;
logic [15:0] blink_num;

// wkr_en
always_ff @( posedge clk_i )
  begin
    if( srst_i )
      begin
        wrk_cntr <= '0;
        wrk_en   <= '0;
      end
    else
      begin
        if( wrk_cntr < ( DELIMITER - 1'b1 ) )
          begin
            wrk_en   <= '0;
            wrk_cntr <= wrk_cntr + 1'b1;
          end
        else
          begin
            wrk_en   <= '1;
            wrk_cntr <= '0;
          end
      end
  end



// FSM blocks
always_ff @( posedge clk_i )
  begin
    if( srst_i )
      begin
        state       <= RED_S;
        red_time    <= RED_TIME_DEFAULT;
        green_time  <= GREEN_TIME_DEFAULT;
        yellow_time <= YELLOW_TIME_DEFAULT;
        blink_num   <= GREEN_BLINKS_NUM;
      end
    
    else if( cmd_valid_i )
      begin
        state <= next_state;
        case( cmd_type_i )
          TURN_ON_CMD: begin
            if( ( state == TURN_OFF_S ) || ( state == UNC_ON_S ) || 
                ( state == UNC_OFF_S ) )
              begin
                state <= RED_S;
                if( state == TURN_OFF_S )
                  begin
                    red_time    <= RED_TIME_DEFAULT;
                    green_time  <= GREEN_TIME_DEFAULT;
                    yellow_time <= YELLOW_TIME_DEFAULT;
                  end
              end
          end
          
          TURN_OFF_CMD: begin
            state <= TURN_OFF_S;
          end
          
          SET_UNC_CMD: begin
            state <= UNC_ON_S;
          end
          
          SET_GREEN_TIME_CMD: begin
            green_time <= cmd_data_i;
          end
          
          SET_RED_TIME_CMD: begin
            red_time <= cmd_data_i;
          end
          
          SET_YELLOW_TIME_CMD: begin
            yellow_time <= cmd_data_i;
          end
          
        endcase
      end
    else if( wrk_en )
      state <= next_state;
      
  end
  
  
always_comb
  begin
    next_state = state;
    case( state )
      RED_S: begin
          next_state = ( cntr_done ) ? RED_YELLOW_S : RED_S;
      end
      
      RED_YELLOW_S: begin
        next_state = ( cntr_done ) ? GREEN_S : RED_YELLOW_S;
      end
      
      GREEN_S: begin
        next_state = ( cntr_done ) ? GREEN_BLINK_OFF_S : GREEN_S;
      end
      
      GREEN_BLINK_OFF_S: begin
        if( blink_done )
          next_state = YELLOW_S;
        else if( cntr_done )
          next_state = GREEN_BLINK_ON_S;
        else
          next_state = GREEN_BLINK_OFF_S;
      end
      
      GREEN_BLINK_ON_S: begin
        if( blink_done )
          next_state = YELLOW_S;
        else if( cntr_done )
          next_state = GREEN_BLINK_OFF_S;
        else
          next_state = GREEN_BLINK_ON_S;
      end
      
      YELLOW_S: begin
        next_state = ( cntr_done ) ? RED_S : YELLOW_S;
      end
      
      TURN_OFF_S: begin 
        next_state = TURN_OFF_S;
      end
      
      UNC_ON_S: begin        
        if( cntr_done )
          next_state = UNC_OFF_S;
        else
          next_state = UNC_ON_S;
      end
      
      UNC_OFF_S: begin
        if( cntr_done )
          next_state = UNC_ON_S;
        else
          next_state = UNC_OFF_S;
      end
      
      default: begin
        next_state = RED_S;
      end
    
    endcase
    
  end
    
  
always_ff @( posedge clk_i )  
  begin
    if( srst_i )
      begin
        blink_done <= '0;
        cntr_done  <= '0;
        blink_cntr <= '0;
        cntr       <= '0;
        unc_cntr   <= '0;
      end
    else if( wrk_en )
      begin : else_block
        unc_cntr <= '0;
        cntr     <= '0;
        case( state )
          RED_S: begin
            if( cntr < ( red_time - 1'b1 ) )
              begin
                cntr      <= cntr + 1'b1;
                cntr_done <= '0;
              end
            else
              begin                
                cntr      <= '0;
                cntr_done <= '1;
              end
          end
          
          RED_YELLOW_S: begin
            if( cntr < ( RED_YELLOW_TIME - 1'b1 ) )
              begin
                cntr      <= cntr + 1'b1;
                cntr_done <= '0;
              end
            else
              begin                
                cntr      <= '0;
                cntr_done <= '1;
              end
          end
          
          GREEN_S: begin
          if( cntr < ( green_time - 1'b1 ) )
              begin
                cntr      <= cntr + 1'b1;
                cntr_done <= '0;
              end
            else
              begin                
                cntr      <= '0;
                cntr_done <= '1;
              end
          end
          
          GREEN_BLINK_OFF_S: begin
          if( cntr < ( BLINK_HALF_PERIOD - 1'b1 ) )
              begin
                cntr       <= cntr + 1'b1;
                cntr_done  <= '0;   
                blink_done <= '0;
              end
            else
              begin
                cntr      <= '0;
                cntr_done <= '1;
                if( blink_cntr < ( blink_num - 1'b1 ) )
                  begin
                    blink_cntr <= blink_cntr + 1'b1;    
                    blink_done <= '0;
                  end
                else
                  begin
                    blink_cntr <= '0;
                    blink_done <= '1;
                  end
                  
              end              
          end
          
          GREEN_BLINK_ON_S: begin
            if( cntr < ( BLINK_HALF_PERIOD - 1'b1 ) )
               begin
                cntr       <= cntr + 1'b1;
                cntr_done  <= '0;   
                blink_done <= '0;
              end
            else
              begin
                cntr      <= '0;
                cntr_done <= '1;
                if( blink_cntr < ( blink_num - 1'b1 ) )
                  begin
                    blink_cntr <= blink_cntr + 1'b1;    
                    blink_done <= '0;
                  end
                else
                  begin
                    blink_cntr <= '0;
                    blink_done <= '1;
                  end
                  
              end 
          end
          
          YELLOW_S: begin
            if( cntr < ( yellow_time - 1'b1 ) )
              begin
                cntr      <= cntr + 1'b1;
                cntr_done <= '0;
              end
            else
              begin                
                cntr      <= '0;
                cntr_done <= '1;
              end
          end
          
          TURN_OFF_S: begin 
            blink_done <= '0;
            cntr_done  <= '0;
            blink_cntr <= '0;
            cntr       <= '0;
          end
          
          UNC_ON_S: begin
            if( unc_cntr < ( BLINK_HALF_PERIOD - 1'b1 ) )
              begin
                unc_cntr  <= unc_cntr + 1'b1;
                cntr_done <= '0;
              end
            else
              begin                
                unc_cntr  <= '0;
                cntr_done <= '1;
              end
          end
          
          UNC_OFF_S: begin
            if( unc_cntr < ( BLINK_HALF_PERIOD - 1'b1 ) )
              begin
                unc_cntr  <= unc_cntr + 1'b1;
                cntr_done <= '0;
              end
            else
              begin                
                unc_cntr  <= '0;
                cntr_done <= '1;
              end
          end
        endcase
      end : else_block
    
  end
  

endmodule 
