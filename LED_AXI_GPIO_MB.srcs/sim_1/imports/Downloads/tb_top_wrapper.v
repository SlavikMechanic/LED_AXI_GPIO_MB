// tb_top_wrapper.v
// Testbench для ПОВНОГО проєкту (design_1_wrapper): MicroBlaze +
// AXI GPIO x3 (LED/BTN/SW) -- УСЕ РАЗОМ, в одній Behavioral
// Simulation, з реальним .elf, пов'язаним через Associate ELF files.
//
// МІСЦЯ, ПОЗНАЧЕНІ "ПЕРЕВІРИТИ" -- залежать від того, як САМЕ
// Vivado назве порти у ВАШІЙ конкретній збірці. Відкрийте
// згенерований design_1_wrapper.v і звірте реальні назви перед
// запуском.

`timescale 1ns / 1ps

module tb_top_wrapper;

    // ---- Такт і reset -- ПЕРЕВІРИТИ реальну назву порту такту у
    // вашій обгортці (залежить від джерела такту, обраного при
    // Block Automation) ----
    // ---- Диференційний такт -- ПЕРЕВІРИТИ реальні назви портів
    // (типово diff_clock_rtl_p/diff_clock_rtl_n чи sys_clk_p/sys_clk_n,
    // залежить від того, як саме назвали цей порт при Make External) ----
    reg diff_clock_rtl_0_clk_p = 0;
    wire diff_clock_rtl_0_clk_n = ~diff_clock_rtl_0_clk_p;   // завжди протифазний до clk_p
    reg reset = 0;   // ПЕРЕВІРИТИ активний рівень (0 чи 1)

    reg reset_rtl_0 = 0;   // ПЕРЕВІРИТИ активний рівень (0 чи 1)

    // ---- Зовнішні GPIO-порти -- перевірені раніше через Make External ----
    tri  [3:0] btn_tri_io_bidir;
    reg  [3:0] btn_tri_io;
    assign btn_tri_io_bidir = btn_tri_io;
    tri  [1:0] sw_tri_io_bidir;
    reg  [1:0] sw_tri_io;
    assign sw_tri_io_bidir = sw_tri_io;
    tri  [3:0] led_tri_io_bidir;
    wire [3:0] led_tri_io;
    assign led_tri_io_bidir = led_tri_io;
    // ---- Інстанціювання ПОВНОЇ верхньої обгортки ----
    // ПЕРЕВІРИТИ точний список портів у вашому файлі design_1_wrapper.v
    design_1_wrapper dut (
        .diff_clock_rtl_0_clk_p (diff_clock_rtl_0_clk_p),   // ПЕРЕВІРИТИ реальну назву
        .diff_clock_rtl_0_clk_n (diff_clock_rtl_0_clk_n),   // ПЕРЕВІРИТИ реальну назву
        .reset_rtl_0      (reset_rtl_0),
        .btn_tri_io  (btn_tri_io_bidir),
        .sw_tri_io   (sw_tri_io_bidir),
        .led_tri_io  (led_tri_io_bidir)
    );

    // ---- Генерація такту (період залежить від реальної частоти
    // вашого проєкту; тут -- приклад для 100 МГц) ----
    always #5 diff_clock_rtl_0_clk_p = ~diff_clock_rtl_0_clk_p;

    // ---- Стимул: імітуємо реальні натискання кнопок ----
    initial begin
        reset_rtl_0 = 1;
        sw_tri_io  = 2'b00;
        btn_tri_io = 4'b0000;
        #200;
        reset_rtl_0 = 0;

        // Дати MicroBlaze час "прокинутись" і дійти до while(1) --
        // орієнтовний запас, скоригувати за спостереженням у Waveform
        #50000;

        $display("[%0t] Тест 1: btn=0011", $time);
        btn_tri_io = 4'b0011;
        #10000;
        $display("[%0t] led_tri_io = %b (очікується 0011 -- пряме дзеркалення)", $time, led_tri_io);

        $display("[%0t] Тест 2: btn=1010", $time);
        btn_tri_io = 4'b1010;
        #10000;
        $display("[%0t] led_tri_io = %b (очікується 1010)", $time, led_tri_io);

        $display("[%0t] Тест 3: btn=1111", $time);
        btn_tri_io = 4'b1111;
        #10000;
        $display("[%0t] led_tri_io = %b (очікується 1111)", $time, led_tri_io);

        btn_tri_io = 4'b0000;
        #10000;

        $display("Симуляція завершена -- перевірте лог вище й Waveform Viewer");
        $finish;
    end

endmodule
