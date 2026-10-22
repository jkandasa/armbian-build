# RK3128 analog audio

Analog audio on the AV jack does not work yet.
This file records the findings for the next step.

## Hardware

The internal audio codec is at 0x20030000.
The register window size is 0x4000.
The codec clock is `PCLK_ACODEC`.
The factory clock name is `g_pclk_acodec`.
The factory firmware connects the codec to `i2s1@10200000`.
That controller is `i2s_8ch`.
HDMI audio uses `i2s_8ch` now.
The factory firmware sends HDMI audio over S/PDIF.
That setup keeps the I2S controller free for the codec.
GRF_SOC_CON0 is at GRF + 0x140.
Bit 10 of GRF_SOC_CON0 is `GRF_ACODEC_SEL`.
That bit routes the I2S signals to the codec.
The vendor driver writes `BIT(10) | BIT(26)`.
GPIO1_A3 enables the amplifier, active high.
The factory property is `spk_ctl_io = <&gpio1 3 0>`.

The factory codec node sets these values.

| Property         | Value  |
| ---------------- | ------ |
| `spk_volume`     | 0x19   |
| `hp_volume`      | 0x19   |
| `hp-mute-delay`  | 100 ms |
| `spk-mute-delay` | 200 ms |
| `boot_depop`     | 1      |
| `is_rk3128`      | 0      |
| `codec_hp_det`   | 0      |

## Driver

The mainline `inno_rk3036` driver does not fit this codec.
Only the I2S interface registers 0x00 to 0x14 match.
The RK3128 codec has more DAC and headphone registers at 0xa0 to 0xbc.
On RK3128, registers 0x88 to 0x9c control the ADC.
The vendor driver is `sound/soc/codecs/rk312x_codec.c`.
The vendor source is the rockchip-linux kernel, branch `develop-4.4`.
A new small codec driver is necessary.
That driver needs only the DAC and the headphone output.

## Registers

The registers are 32 bits wide.
The register stride is 4.
Only the low 8 bits hold data.

| Register                                 | Offset         |
| ---------------------------------------- | -------------- |
| RESET                                    | 0x00           |
| ADC_INT_CTL1, ADC_INT_CTL2               | 0x08, 0x0c     |
| DAC_INT_CTL1, DAC_INT_CTL2, DAC_INT_CTL3 | 0x10, 0x14, 0x18 |
| ALC_CTL                                  | 0x28           |
| ADC_MIC_CTL, BST_CTL, ALC_MUNIN_CTL      | 0x88, 0x8c, 0x90 |
| BSTL_ALCL_CTL, ALCR_GAIN_CTL, ADC_ENABLE | 0x94, 0x98, 0x9c |
| DAC_CTL, DAC_ENABLE                      | 0xa0, 0xa4     |
| HPMIX_CTL, HPMIX_S_SELECT                | 0xa8, 0xac     |
| HPOUT_CTL, HPOUTL_GAIN, HPOUTR_GAIN      | 0xb0, 0xb4, 0xb8 |
| SELECT_CURRENT                           | 0xbc           |
| PGA AGC                                  | 0x100 to 0x164 |

## Reset

Write 0x00 to RESET.
Wait 10 ms.
Write 0x43 to RESET.
Wait 10 ms.
A read of RESET then returns 0x03.

## Playback power-up

Write these values in this order.
Each line is a register offset and a value.
0xb4 and 0xb8 set the volume.

```
0x18 0x32
0xa0 0x48
0xa0 0x6a
0xb4 0x80
0xb8 0x80
0xa8 0x44
0xa8 0x55
0xb0 0x90
0xb0 0xd8
0xa4 0x88
0xa4 0xcc
0xa4 0xee
0xa4 0xff
0xac 0x11
0xa8 0x77
0xb0 0xfc
0xb4 0x19
0xb8 0x19
0xb0 0xff
0xa0 0x7b
```

## Playback power-down

```
0xb0 0xdb
0xa8 0x44
0xac 0x00
0xb0 0x92
0xa0 0x2a
0xb0 0x00
0xa8 0x00
0xa4 0x00
0xa0 0x08
0x18 0x22
0xb4 0x00
0xb8 0x00
```

## Interface

The codec is the I2S slave (`CBS_CFS`).
DAC_INT_CTL1 sets the format, the LRCK polarity, and the valid word length.
DAC_INT_CTL2 sets the BCLK polarity, the word length, and the DAC reset release.
The vendor driver expects MCLK at 256 fs.
The vendor driver expects BCLK at MCLK / 4.
The vendor driver sets GPIO1_A3 high after unmute.
The unmute delay is 200 ms.

## Next steps

1. Test from user space first.
   Ungate `PCLK_ACODEC`.
   Set `GRF_ACODEC_SEL`.
   Set GPIO1_A3 high.
   Reset the codec.
   Write the power-up sequence through `/dev/mem`.
   Play audio on the HDMI card.
   Listen on the AV jack.
2. Write an ASoC codec driver `rockchip,rk3128-codec` when the test gives sound.
   The driver needs the reset, the DAI setup, the power sequences, a volume control, and the amplifier GPIO.
3. Add a codec node and a sound card to the device tree.
   HDMI and the codec share `i2s_8ch`.
   Use one `simple-audio-card` DAI link with two codecs.
   Or move HDMI audio to S/PDIF, as the factory firmware does.
