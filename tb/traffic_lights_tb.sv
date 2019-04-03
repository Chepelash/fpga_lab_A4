//`timescale 10ns/1ns
`timescale 1ns/1ns

module traffic_lights_tb;

parameter int CLK_T = 10;
parameter int DELIMITER = 100000;
//parameter int DELIMITER = 10;

parameter  logic [15:0] BLINK_HALF_PERIOD   = 5;
parameter  logic [15:0] GREEN_BLINKS_NUM    = 4;
parameter  logic [15:0] RED_YELLOW_TIME     = 5;
parameter  logic [15:0] RED_TIME_DEFAULT    = 5;
parameter  logic [15:0] YELLOW_TIME_DEFAULT = 5;
parameter  logic [15:0] GREEN_TIME_DEFAULT  = 5;


enum logic [2:0] {TURN_ON_CMD         = 3'd0,
                  TURN_OFF_CMD        = 3'd1,
                  SET_UNCONTR_CMD     = 3'd2,
                  SET_GREEN_TIME_CMD  = 3'd3,
                  SET_RED_TIME_CMD    = 3'd4,
                  SET_YELLOW_TIME_CMD = 3'd5} commands;

logic        clk;
logic        rst;

logic [2:0]  cmd_type_i;
logic        cmd_valid_i;
logic [15:0] cmd_data_i;

logic        red_o;
logic        yellow_o;
logic        green_o;


logic [15:0] red_time;
logic [15:0] yellow_time;
logic [15:0] green_time;

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

  for( int d = 0; d < DELIMITER+1; d++ )
        @( posedge clk );
    
  
  $write("Red light -- ");
  for( int i = 0; i < red_time; i++ )
    begin
      if( ( red_o != 1 ) || ( yellow_o != 0 ) || ( green_o != 0 ) )
        begin
          $display("Fail!\nNormal functionning: red_s error");
          $stop();
        end
      for( int d = 0; d < DELIMITER; d++ )
        @( posedge clk );
    end
  $display("OK!");

  
  $write("Red-yellow light -- ");
  for( int i = 0; i < RED_YELLOW_TIME; i++ )
    begin
      if( ( red_o != 1 ) || ( yellow_o != 1 ) || ( green_o != 0 ) )
        begin
          $display("Fail!\nNormal functionning: red_yellow_s error");
          $stop();
        end
      for( int d = 0; d < DELIMITER; d++ )
        @( posedge clk );
    end
  $display("OK!");
  
  $write("Green light -- ");
  for( int i = 0; i < green_time; i++ )
    begin
      if( ( red_o != 0 ) || ( yellow_o != 0 ) || ( green_o != 1 ) )
        begin
          $display("Fail!\nNormal functionning: green_s error");
          $stop();
        end
      for( int d = 0; d < DELIMITER; d++ )
        @( posedge clk );
    end
   
  $display("OK!");
  
  $write("Green blinks -- ");
  for( int j = 0; j < GREEN_BLINKS_NUM; j++ )
    begin
      for( int i = 0; i < BLINK_HALF_PERIOD; i++ )
        begin
          if( ( red_o != 0 ) || ( yellow_o != 0 ) || ( green_o != ( j % 2 ) ) )
            begin
              $display("Fail!\nNormal functionning: green_blink_s error");
              $stop();
            end
          
          for( int d = 0; d < DELIMITER; d++ )
            @( posedge clk );
        end
    end
    
  $display("OK!");
    
  $write("Yellow light -- ");
  for( int i = 0; i < yellow_time; i++ )
    begin
      if( ( red_o != 0 ) || ( yellow_o != 1 ) || ( green_o != 0 ) )
        begin
          $display("Fail!\nNormal functionning: yellow_s error");
          $stop();
        end
      for( int d = 0; d < DELIMITER; d++ )
        @( posedge clk );
    end
  $display("OK!");
  
  $write("Red light again -- ");
  for( int i = 0; i < red_time; i++ )
    begin
      if( ( red_o != 1 ) || ( yellow_o != 0 ) || ( green_o != 0 ) )
        begin
          $display("Fail!\nNormal functionning: red_s error");
          $stop();
        end
      for( int d = 0; d < DELIMITER; d++ )
        @( posedge clk );
    end
  $display("OK!");
  
endtask


task automatic test_commands;
  
  $write("Testing uncontrollable state -- ");
  send_cmd(16'd0, SET_UNCONTR_CMD);
//  @( posedge clk );
//  @( posedge clk );  // first iteration BLINK_HALF_PERIOD + 1 ????
  @( negedge yellow_o );
  @( posedge clk );
  for( int i = 0; i < 5; i++ )
    begin
      for( int j = 0; j < BLINK_HALF_PERIOD; j++ )
        begin
          if( yellow_o != ( i % 2 ) )
            begin
              $display("Error in uncontrollable_s.");
              $stop();
            end
          
          for( int d = 0; d < DELIMITER; d++ )
            @( posedge clk ); 
        end
    end
    $display("OK!");
    
  $display();    
  $display("Changing red, yellow and green light time to 10 ms");
  send_cmd(16'd10, SET_RED_TIME_CMD);
  send_cmd(16'd10, SET_YELLOW_TIME_CMD);
  send_cmd(16'd10, SET_GREEN_TIME_CMD);
  
  $display("Testing another timings");
  red_time    = 10;
  yellow_time = 10;
  green_time  = 10;
  
  send_cmd(16'd0, TURN_ON_CMD);
  @( posedge clk );
  test_normal_work();
  $display("Timings changed!\n");
  
  $display("Turning off");
  send_cmd(16'd0, TURN_OFF_CMD);
  @( posedge clk );
  for( int i = 0; i < 50; i++ )
    begin
      if( ( red_o != '0 ) || ( yellow_o != '0 ) || ( green_o != '0 ) )
        begin
          $display("Error in turn off state");
          $stop();
        end
        for( int d = 0; d < DELIMITER; d++ )
            @( posedge clk );
    end
  $display("Turning off is OK\n");
  
  $display("Turning on again");
  red_time = 5;
  yellow_time = 5;
  green_time = 5;
  send_cmd(16'd0, TURN_ON_CMD);
  @( posedge clk );
  test_normal_work();
  $display("It's turning on and resetting!\n");
  

endtask


initial
  begin
    clk <= '1;
    rst <= '0;
    
    red_time    = RED_TIME_DEFAULT;
    yellow_time = YELLOW_TIME_DEFAULT;
    green_time  = GREEN_TIME_DEFAULT;
    
    fork
      clk_gen();
    join_none
    
    fork
      apply_rst();
    join
    
    $display("Starting testbench!");
    
    $display("\n----------------------------------------------");
    $display("Testing normal functionning...\n");
    test_normal_work();
    $display("\nNormal functionning -- OK!");
    $display("----------------------------------------------");
    

    $display("Testing input commands...\n");
    test_commands();
    $display("\nCommands are OK!");
    $display("----------------------------------------------");
    
    $display("\nEverything is fine.");

    
//    for( int unsigned i = 0; i < 1000000; i++ )
//      @( posedge clk );
    
    
    $stop();
  end


endmodule
