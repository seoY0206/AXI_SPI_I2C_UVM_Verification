`timescale 1ns / 1ps

module tb_spi_master ();

    // global signals
    logic       clk;
    logic       reset;
    // Master internal signals
    logic       start;
    logic       cpol;
    logic       cpha;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic       tx_ready;
    logic       done;
    // SPI external ports
    logic       sclk;
    logic       mosi;
    logic       miso;
    logic       cs;

    // Slave Internal signals
    logic [7:0] si_data;  //rx_data = slave_in_data
    logic       si_done;  //rx_done
    logic [7:0] so_data;  //tx_data = slave_out_data
    logic       so_start;  //tx_start
    logic       so_ready;  //tx_ready

    spi_master dut_master (.*);

    spi_slave dut_slave (.*);

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        #10;
        reset = 0;
    end

    task automatic spi_mode(bit pha, bit pol);
        cpol = pol;
        cpha = pha;
        @(posedge clk);
    endtask  //automatic

    task automatic spi_write(byte data);
        @(posedge clk);
        cs = 1'b0;
        wait (tx_ready);
        start   = 1;
        tx_data = data;
        @(posedge clk);
        start = 0;
        wait (done);
        @(posedge clk);
        cs = 1'b1;
    endtask  //automatic

    task automatic spi_slave_out(byte data);
        @(posedge clk);
        wait (so_ready);
        so_data  = data;
        so_start = 1;

        @(posedge clk);
        so_start = 0;
        wait (so_ready);
    endtask  //automatic

    initial begin
        repeat (5) @(posedge clk);

        spi_mode(1'b0, 1'b0);  //mode0
        fork
            spi_write(8'hf0);
            spi_slave_out(8'haa);
        join
        //spi_write(8'h0f);
        //spi_write(8'haa);
        //spi_write(8'h55);

        #20;
        $finish;
    end

endmodule
