const std = @import("std");
const Builder = std.build.Builder;
const builtin = @import("builtin");

const CrossTarget = std.zig.CrossTarget;


fn c_compile(c_file: []const u8) []const u8 {

}

pub fn build(b: *Builder) !void {
    const target = CrossTarget{
        .cpu_arch = .aarch64,
        .os_tag = .freestanding,
        .cpu_model = .{ .explicit = &std.Target.aarch64.cpu.cortex_a53 },
    };
    
    const kernel = b.addExecutable("kernel", "src/main.zig");
    const mode = b.standardReleaseOptions();
    kernel.setBuildMode(mode);
//    kernel.addIncludeDir("./core");
//    kernel.addObjectFile("./core/core.a");
    kernel.addAssemblyFile("src/start.S");
    kernel.setTarget(target);
    kernel.setLinkerScriptPath("linker.ld");
    kernel.setOutputDir("zig-cache");
    kernel.verbose_cc = false;
    kernel.verbose_link = false;
    // kernel.setBuildMode(builtin.Mode.ReleaseFast);
    // kernel.strip = true;

//    const run_objcopy = b.addSystemCommand(&[_][]const u8{
//        "llvm-objcopy", kernel.getOutputPath(),
//        "-O",           "binary",
//        "zig-cache/kernel.img",
//    });


    const qemu = b.step("qemu", "Run the OS in qemu");
    var qemu_args = std.ArrayList([]const u8).init(b.allocator);
    try qemu_args.appendSlice(&[_][]const u8{
        "qemu-system-aarch64",
        "-kernel",
        kernel.getOutputPath(),
        "-m",
        "256",
        "-M",
        "raspi3",
        "-serial",
        "null",
        "-serial",
        "stdio",
        "-display",
        "none",
    });

    const run_qemu = b.addSystemCommand(qemu_args.items);
    qemu.dependOn(&run_qemu.step);

    // run_objcopy.step.dependOn(&kernel.step);
    run_qemu.step.dependOn(&kernel.step);
    
    b.default_step.dependOn(&kernel.step);
}
