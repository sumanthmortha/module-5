`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.04.2024 10:03:10
// Design Name: 
// Module Name: top
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


module top #(parameter confi = 40)(

    input clk,
    input reset_n,
    
    // input ports
    input [15:0]input_tdata,
    input input_tvalid,
    input [4:0]input_tkeep,
    input input_tlast,
    output input_tready,
    
    // output ports
    output [15:0]output_tdata,
    output output_tvalid,
    output [4:0] output_tkeep,
    output output_tlast,
    input output_tready

    );
    
    logic [21:0]output_data_1_fifo;
    logic output_ready_1_fifo;
    logic output_valid_1_fifo;
    logic [15:0]tdata = 0;
    logic [15:0]tdata_mid = 0;
    logic [4:0]tkeep = 0;
    logic tlast = 0;
    logic [6:0]count;
    
    logic r_w_en;
    logic r_r_en;
    logic w_en;
    logic r_en;
    
    logic [15:0]r_input_tdata;           // registers for the inputs
    logic [4:0]r_input_tkeep;
    logic r_input_tlast;
    logic r_input_tvalid;
    
   
    
    logic [15:0]r_output_tdata = 0;               // registering for outputs
    logic r_output_tvalid = 0;
    logic [4:0]r_output_tkeep = 0;
    logic r_output_tlast = 0;
    
    
    // registering the inputs 
    always_ff@(posedge clk)             
    begin
          if(!reset_n) 
          begin
                 r_input_tdata <= 0;
                 r_input_tkeep <= 0;
                 r_input_tlast <= 0;
                 r_input_tvalid <= 0;
          end
          else 
          begin
                 r_input_tdata <= input_tdata;
                 r_input_tkeep <= input_tkeep;
                 r_input_tlast <= input_tlast;
                 r_input_tvalid <= input_tvalid;                
          end
    end
    
    
    // here we are filtering input data according to tkeep
    //assign fifo_wire_1 = r_input_tdata << (5'd16 - r_input_tkeep);
    //assign w_input_tdata = fifo_wire_1 >> (5'd16 - r_input_tkeep);
    

     
    // Define states using one-hot encoding
     enum logic [5:0] {
        idle,
        read,
        real_read,
        real_read1,
        count_match,
        process1,
        process2 
    } present_state , next_state;
    
    // instantiating the fifo
    fifo f1 (
        .clk(clk),
        .reset_n(reset_n),
        .w_en(w_en),
        .r_en(r_r_en),
        .input_tdata({r_input_tlast,r_input_tdata,r_input_tkeep}),
        .input_tvalid(r_input_tvalid),
        .input_tready(input_tready),
        .output_data(output_data_1_fifo),
        .output_ready(output_ready_1_fifo),
        .output_valid(output_valid_1_fifo)
);

always_ff@(posedge clk)
    begin
    if(!reset_n) present_state <= idle;
    else present_state <= next_state;
    end

//next_state logic    
always_comb
begin
    case(present_state)
                     idle :     begin
                                r_en = 0;
                                if(r_input_tdata == 0) next_state = idle;
                                else next_state = read;
                                end
                     read :     begin
                                r_en = 1; 
                                next_state = real_read;
                                end 
                     real_read: begin
                                r_en = 0;
                                next_state = real_read1;
                                end
                     real_read1:begin
                                next_state = count_match;
                                end  
                     count_match: 
                                begin
                                r_en = 0;
                                next_state = process1;
                                end          
                                         
                     process1 : begin
                                r_en = 0;
                                if(count > confi) next_state = process2;
                                else next_state = read;
                                end    
                     process2 : begin
                                r_en = 0;
                                next_state = read; 
                                end     
    endcase
end

always_ff@(posedge clk)
begin
       case(present_state)
                    idle :     begin
                               //r_en <= 0;
                               end
                    read :     begin
                               //r_en <=1;
                               end
                    real_read1: begin
                               //r_en <= 0;
                               {tlast,tdata,tkeep} <= output_data_1_fifo;
                               end                      
                    process1 : begin
                               //r_en <= 0;
                               if (count < confi)
                                    begin
                                       r_output_tdata <= tdata;
                                       r_output_tkeep <= tkeep;
                                       r_output_tlast <= tlast;                                      
                                    end
                                else if(count == confi)
                                       begin
                                        r_output_tdata <= tdata ;
                                        r_output_tkeep <= tkeep;
                                        r_output_tlast <= 1; 
                                       end
                                else begin
                                       r_output_tdata <= tdata << count-confi;
                                       r_output_tkeep <= 5'd16 - (count - confi);
                                       r_output_tlast <= 1;
                                       tdata_mid <= tdata >> 5'd16 - (count - confi);
                                    end

                               end
                    process2 : begin
                                     r_output_tdata <= tdata_mid;
                                     r_output_tkeep <= count;
                                     r_output_tlast <= tlast; 
                               end
                                       
       endcase
end

// block for registering 
always_ff@(posedge clk)
begin
      if(!reset_n) 
          begin
          r_r_en <= 0;
          r_w_en <= 0;
          output_ready_1_fifo <= 0;
          end
      else 
          begin
          r_r_en <= r_en;
          output_ready_1_fifo <= 1;
          r_w_en <= 1;
          end
end

//block for counter
always_ff@(posedge clk)
begin
      case(present_state)
                      idle : count <= 0;
                      count_match : count <= count +tkeep;
                      process1 : if(count == confi) count <= 0;
                                 else if (count > confi)count <= count - confi;
                                 else count <= count;
      endcase


end


assign w_en = r_w_en;
assign output_tdata = r_output_tdata;
assign output_tkeep = r_output_tkeep;
assign output_tlast = r_output_tlast;
assign output_tvalid = r_output_tvalid;
endmodule
