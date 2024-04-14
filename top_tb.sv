`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.04.2024 11:55:31
// Design Name: 
// Module Name: top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_tb;

  // Parameters

  //Ports
  reg  clk;
  reg  reset_n;
  reg [15:0] input_tdata;
  reg [15:0]s_tdata_i; 
  reg [4:0]s_tkeep_i;
  reg s_tlast_i;                                                  
  reg  input_tvalid;
  reg [4:0] input_tkeep;
  reg  input_tlast;
  wire  input_tready;
  wire [15:0] output_tdata;
  wire  output_tvalid;
  wire [4:0] output_tkeep;
  wire  output_tlast;
  reg  output_tready;

integer file;

  top  top_inst (
    .clk(clk),
    .reset_n(reset_n),
    .input_tdata(input_tdata),
    .input_tvalid(input_tvalid),
    .input_tkeep(input_tkeep),
    .input_tlast(input_tlast),
    .input_tready(input_tready),
    .output_tdata(output_tdata),
    .output_tvalid(output_tvalid),
    .output_tkeep(output_tkeep),
    .output_tlast(output_tlast),
    .output_tready(output_tready)
  );

always #5  clk = ! clk ;

initial begin
    input_tdata = 0;
    input_tvalid = 0;
    input_tkeep = 0;
    input_tlast = 0;
    output_tready = 1;
    clk=0;
    reset_n=0;
    reset;
    fork begin
    axis_write(11);
    end
    begin
    end   
    join
    
    end
    
    task automatic reset;
      begin
       repeat (3) @(posedge clk);
          reset_n = ~reset_n;
        end
    endtask
    
      task automatic axis_write(input [9:0] n);
        file = $fopen("input_dat.mem", "r");
          if (file == 0)
          begin
            $stop("Error in Opening file !!");
          end
        @(posedge clk);
        
        repeat (n) begin
        if (output_tready) begin
       // @(posedge clk);
        $fscanf(file,"%h %d %b",s_tdata_i,s_tkeep_i,s_tlast_i);
        
    
            input_tdata<=s_tdata_i;
            input_tkeep<=s_tkeep_i;
            input_tlast<=s_tlast_i;
            input_tvalid<=1;
            @(posedge clk);
         end
         else begin
            
            @(posedge clk);
                    
                    input_tvalid <= 0;
                    input_tdata<=input_tdata;
                    end
      
           
          
          //  $display("%d,%b",s_tdata,s_tlast);
          
        end
        input_tvalid<=0;
        $fclose(file);
      endtask
    
endmodule