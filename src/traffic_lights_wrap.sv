module traffic_lights_wrap #(
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

logic        srst_i_wrap;

logic [2:0]  cmd_type_i_wrap;
logic        cmd_valid_i_wrap;
logic [15:0] cmd_data_i_wrap;

logic        red_o_wrap;
logic        yellow_o_wrap;
logic        green_o_wrap;


traffic_lights        #(
  .BLINK_HALF_PERIOD   ( BLINK_HALF_PERIOD   ),
  .GREEN_BLINKS_NUM    ( GREEN_BLINKS_NUM    ),
  .RED_YELLOW_TIME     ( RED_YELLOW_TIME     ),
  .RED_TIME_DEFAULT    ( RED_TIME_DEFAULT    ),
  .YELLOW_TIME_DEFAULT ( YELLOW_TIME_DEFAULT ),
  .GREEN_TIME_DEFAULT  ( GREEN_TIME_DEFAULT  )
) traffic_lights_1     (
  .clk_i               ( clk_i               ),
  .srst_i              ( srst_i_wrap         ),

  .cmd_type_i          ( cmd_type_i_wrap     ),
  .cmd_valid_i         ( cmd_valid_i_wrap    ),
  .cmd_data_i          ( cmd_data_i_wrap     ),

  .red_o               ( red_o_wrap          ),
  .yellow_o            ( yellow_o_wrap       ),
  .green_o             ( green_o_wrap        )
);


always_ff @( posedge clk_i )
  begin
    
    srst_i_wrap      <= srst_i;
    
    cmd_type_i_wrap  <= cmd_type_i;
    cmd_valid_i_wrap <= cmd_valid_i;
    cmd_data_i_wrap  <= cmd_data_i;
    
    red_o            <= red_o_wrap;
    yellow_o         <= yellow_o_wrap;
    green_o          <= green_o_wrap;
    
  end


endmodule
