local CONF = {
	BIOS = {
		-- Todo: More descriptive names
		FIRST = "ALASKA",
		SECOND = "ASPC    ",
		VENDOR = "AMI"
	},

	DISK = {
		NAME = "WDC WD10JPVX-22JC3T0",
		VENDOR = "Western Digital Technologies, Inc."
	},

	CD = {
		NAME = "ASUS DRW 24F1ST",
		VENDOR = "ASUS"
	},

	TABLET = {
		NAME = "Wacom Tablet",
		VENDOR = "Wacom"
	},

	CPU = {
		SPEED = 2277, -- MHz
		BRAND = "GenuineIntel"
	}
}

local q = function(s) return '"' .. s .. '"' end
local escape_pattern = function(s) return s:gsub("%W", "%%%1") end

local DIFFS = {
	["include/hw/acpi/aml-build.h"] = {
		{q"BOCHS", q(CONF.BIOS.FIRST)},
		{q"BXPC    ", q(CONF.BIOS.SECOND)}
	},

	["block/bochs.c"] = {
		{q"BOCHS", q(CONF.BIOS.VENDOR)}
	},

	["hw/scsi/scsi-disk.c"] = {
		{q"QEMU", q(CONF.DISK.VENDOR)},
		{q"QEMU HARDDISK", q(CONF.DISK.NAME)},
	},

	["hw/ide/core.c"] = {
		{q"QEMU HARDDISK", q(CONF.DISK.NAME)},
		{q"QEMU DVD-ROM", q(CONF.CD.NAME)},
	},

	["hw/ide/atapi.c"] = {
		{q"QEMU", q(CONF.CD.VENDOR)},
		{q"QEMU DVD-ROM", q(CONF.CD.NAME)},
	},

	["hw/usb/dev-wacom.c"] = {
		{q"QEMU", q(CONF.TABLET.VENDOR)},
		{q"Wacom PenPartner", q(CONF.TABLET.NAME)},
		{q"QEMU PenPartner Tablet", q(CONF.TABLET.NAME)},
	},

	["hw/smbios/smbios.c"] = {
		{"#define DEFAULT_CPU_SPEED 2000", "#define DEFAULT_CPU_SPEED " .. CONF.CPU.SPEED}
	},

	["include/standard-headers/asm-x86/kvm_para.h"] = {
		{[[KVMKVMKVM\0\0\0]], CONF.CPU.BRAND}
	},

	["target/i386/kvm/kvm.c"] = {
		{[[KVMKVMKVM\0\0\0]], CONF.CPU.BRAND}
	}
}

for file, diffs in pairs(DIFFS) do
	local handle = assert(io.open(file, "rb"), "Failed to open")
	local content = handle:read("*a")
	handle:close()

	for _, diff in ipairs(diffs) do
		local replace = escape_pattern(diff[1])
		local with = diff[2]

		content = string.gsub(content, replace, with)
	end

	local handle = assert(io.open(file, "wb"), "Failed to open")
	handle:write(content)
	handle:close()
end