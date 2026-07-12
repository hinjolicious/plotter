# Red Plotter Library

A lightweight, feature-rich 2D charting engine written in pure **Red**. This library allows you to effortlessly turn numeric blocks into clean, scalable vector graphics using Red's `Draw` dialect. It supports multiple rendering modes, customizable legends, axis normalization, and a built-in polynomial trend-fitting option.

## Features

* **Multiple Graph Styles:** Render native `scatter` plots (with 8 distinct marker shapes), continuous `line` plots, or vertical `histogram` distributions.
* **Auto-Scaling Engine:** Automatically computes smart axis ranges and visual subdivisions (`nice-range` & `nice-bands`), with manual configuration overrides.
* **Interactive Modifiers:** Built-in Least-Squares Quadratic Regression (`/fit`) generates trend-lines automatically over raw point series.
* **Red/Draw Native Integration:** Outputs high-performance raw Draw commands ready to be plugged directly into any UI `box` or `base` face.

---

## Architecture & Requirements

The engine relies on two standard layout helpers and pairs exceptionally well with a frequency distribution processor for histogram rendering.

```red
#include %nice-range.red
#include %nice-bands.red
#include %freq-dist.red     ; Optional: For compiling raw data into histograms

```

---

## API Reference

### `PLOTTER/plot`

```red
PLOTTER/plot canvas-size data [/title ttl] [/x-label xl] [/y-label yl] [/x-range xr] [/y-range yr] [/x-bands xb] [/y-bands yb]

```

#### Arguments

* **`canvas-size`** `[pair!]` — The target rendering width and height (e.g., `600x400`).
* **`data`** `[block!]` — A nested block defining data series metadata alongside structured coordinate payloads.

#### Data Input Specification

The `data` block is compiled as an array of series. Each series contains a header profile block followed by an interleaved coordinate stream:

```red
[
    [type label color marker thickness fit?] [x1 y1 x2 y2 ... xN yN]
]

```

* **`type`**: `'scatter`, `'line`, or `'histogram`
* **`label`**: `[string!]` Display label for the chart legend box.
* **`color`**: `[tuple!]` RGB color descriptor (e.g., `255.0.0`).
* **`marker`**: Used by scatter plots (`'dot`, `'box`, `'triangle`, `'triangle-down`, `'triangle-left`, `'triangle-right`, `'cross`, `'plus`). Use `none` for lines/histograms.
* **`thickness`**: `[integer! | float!]` Structural width for lines/markers, or proportional spacing widths for bars.
* **`fit?`**: Pass `'fit` to automatically compute and append a quadratic regression curve to this sequence.

---

## Detailed Implementation Examples

### 1. Generating Multi-Series Scatter & Trend-Lines

Mix scatter configurations with automatic polynomial curves over the same baseline timeline.

```red
view [
    title "Scientific Regression Sample"
    size 640x480
    base 600x400 white draw (
        PLOTTER/plot 600x400 [
            ;; Scatter series setup with an automatic 'fit flag
            [['scatter "Experimental Data" 255.50.50 'dot 4 'fit] [
                1.0 12.0
                2.0 19.0
                3.0 31.0
                4.0 48.0
                5.0 65.0
            ]]
        ]
        /title "System Node Growth Velocity"
        /x-label "Elapsed Interval (Seconds)"
        /y-label "Throughput Index"
    )
]

```

### 2. Combining with `freq-dist` for Histograms

Use your data binning function to group values into clusters, switch the format into `/plot-output`, and render it instantly as a histogram.

```red
;; 1. Collect arbitrary continuous numbers
raw-metrics: [1.2 1.5 1.7 2.8 2.9 3.1 3.2 3.4 3.9 4.1 4.8 5.0]

;; 2. Bin into 4 groups formatted natively for Red/Draw 
histogram-coordinates: freq-dist/plot-output raw-metrics 4

;; 3. Generate the view frame layout
view [
    title "Statistical Distributions"
    size 640x480
    base 600x400 white draw (
        PLOTTER/plot 600x400 reduce [
            ;; Header specs tailored for structural histograms
            [['histogram "Density Variance" 50.120.240 none 0.8 none] histogram-coordinates]
        ]
        /title "Operational Bin Distributions"
        /x-label "Bound Intervals"
        /y-label "Frequency Count"
    )
]

```

---

## Visual & Configuration Tweaks

To alter font sizing, margin offsets, or border spacings globally across your drawing context, adjust the inner `plot-config` attributes directly before executing a plot query:

```red
PLOTTER/plot-config/margin: 60x50     ; Increase padding spaces for long labels
PLOTTER/plot-config/scale-size: 10   ; Enlarge axis tick numeric outputs

```

## License

Open-source and free to adapt. Maintained and curated by [@hinjolicious](https://www.google.com/search?q=https://github.com/hinjolicious).

```

```