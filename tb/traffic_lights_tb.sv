`timescale 1ms/1ms

module traffic_lights_tb;

parameter int CLK_T = 10;

parameter  logic [15:0] BLINK_HALF_PERIOD   = 5;
parameter  logic [15:0] GREEN_BLINKS_NUM    = 4;
parameter  logic [15:0] RED_YELLOW_TIME     = 5;
parameter  logic [15:0] RED_TIME_DEFAULT    = 5;
parameter  logic [15:0] YELLOW_TIME_DEFAULT = 5;
parameter  logic [15:0] GREEN_TIME_DEFAULT  = 5;

localparam logic [2:0]  TURN_ON_CMD         = 3'd0;
localparam logic [2:0]  TURN_OFF_CMD        = 3'd1;
localparam logic [2:0]  SET_UNCONTR_CMD     = 3'd2;
localparam logic [2:0]  SET_GREEN_TIME_CMD  = 3'd3;
localparam logic [2:0]  SET_RED_TIME_CMD    = 3'd4;
localparam logic [2:0]  SET_YELLOW_TIME_CMD = 3'd5;

logic        clk;
logic        rst;

logic [2:0]  cmd_type_i;
logic        cmd_valid_i;
logic [15:0] cmd_data_i;

logic        red_o;
logic        yellow_o;
logic        green_o;


traffic_lights        #(
  .BLINK_HALF_PERIOD   ( BLINK_HALF_PERIOD   ),
  .GREEN_BLINKS_NUM    ( GREEN_BLINKS_NUM    ),
  .RED_YELLOW_TIME     ( RED_YELLOW_TIME     ),
  .RED_TIME_DEFAULT    ( RED_TIME_DEFAULT    ),
  .YELLOW_TIME_DEFAULT ( YELLOW_TIME_DEFAULT ),
  .GREEN_TIME_DEFAULT  ( GREEN_TIME_DEFAULT  )
) DUT (
  .clk_i               ( clk                 ),
  .srst_i              ( rst                 ),

  .cmd_type_i          ( cmd_type_i          ),
  .cmd_valid_i         ( cmd_valid_i         ),
  .cmd_data_i          ( cmd_data_i          ),

  .red_o               ( red_o               ),
  .yellow_o            ( yellow_o            ),
  .green_o             ( green_o             )
);


task automatic clk_gen;

  forever
    begin
      # ( CLK_T / 2 );
      clk <= ~clk;
    end
  
endtask


task automatic apply_rst;
  
  rst <= 1'b1;
  @( posedge clk );
  rst <= 1'b0;
  @( posedge clk );

endtask


task automatic send_cmd;
  input [15:0] cmd_data;
  input [2:0]  cmd_type;
  
  begin
    cmd_data_i  <= cmd_data;
    cmd_type_i  <= cmd_type;
    cmd_valid_i <= '1;
    @( posedge clk );
    cmd_data_i  <= '0;
    cmd_valid_i <= '0;
    cmd_type_i  <= '0;
  end
endtask


task automatic test_normal_work;

  @( posedge clk );
  @( posedge clk );
  
  $display("Red light");
  for( int i = 0; i < RED_TIME_DEFAULT; i++ )
    begin
      if( ( red_o != 1 ) || ( yellow_o != 0 ) || ( green_o != 0 ) )
        begin
          $display("Normal functionning: red_s error");
          $stop();
        end
      @( posedge clk );
    end
    
//  @( posedge clk );
  
  $display("Red-yellow light");
  for( int i = 0; i < RED_YELLOW_TIME; i++ )
    begin
      if( ( red_o != 1 ) || ( yellow_o != 1 ) || ( green_o != 0 ) )
        begin
          $display("Normal functionning: red_yellow_s error");
          $stop();
        end
      @( posedge clk );
    end
  
//  @( posedge clk );
  
  $display("Green light");
  for( int i = 0; i < GREEN_TIME_DEFAULT; i++ )
    begin
      if( ( red_o != 0 ) || ( yellow_o != 0 ) || ( green_o != 1 ) )
        begin
          $display("Normal functionning: green_s error");
          $stop();
        end
      @( posedge clk );
    end
   
//  @( posedge clk );
  
  $display("Green blinks");
  for( int j = 0; j < GREEN_BLINKS_NUM; j++ )
    begin
      for( int i = 0; i < BLINK_HALF_PERIOD; i++ )
        begin
          if( ( red_o != 0 ) || ( yellow_o != 0 ) || ( green_o != ( j % 2 ) ) )
            begin
              $display("Normal functionning: green_blink_s error");
              $stop();
            end
          
          @( posedge clk );
        end
    end
    
//  @( posedge clk );
    
  $display("Yellow light");
  for( int i = 0; i < YELLOW_TIME_DEFAULT; i++ )
    begin
      if( ( red_o != 0 ) || ( yellow_o != 1 ) || ( green_o != 0 ) )
        begin
          $display("Normal functionning: yellow_s error");
          $stop();
        end
      @( posedge clk );
    end
  
  @( posedge clk );
  
  $display("Red light again");
  for( int i = 0; i < RED_TIME_DEFAULT; i++ )
    begin
      if( ( red_o != 1 ) || ( yellow_o != 0 ) || ( green_o != 0 ) )
        begin
          $display("Normal functionning: red_s error");
          $stop();
        end
      @( posedge clk );
    end
  
endtask


initial
  begin
    clk <= '1;
    rst <= '0;
    
    fork
      clk_gen();
    join_none
    
    fork
      apply_rst();
    join
//    rst <= '1;
//    @( posedge clk );
//    rst <= '0;
//    @( posedge clk );
//    
    $display("Starting testbench!");
    
    $display("\n----------------------------------------------");
    $display("Testing normal functionning. It might take a couple of minutes!");
//    test_normal_work();
    for( int i = 0; i < 100000; i++ )
      @( posedge clk );
    
    
    $stop();
  end


endmodule
