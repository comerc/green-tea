package main

import (
	"fmt"
	"runtime"
	"runtime/debug"
	"time"
)

// PointerBlock is a pointer-heavy structure (128 bytes)
// This density of pointers is ideal for Green Tea's vectorized scanning.
type PointerBlock struct {
	P0, P1, P2, P3, P4, P5, P6, P7 *PointerBlock
	P8, P9, PA, PB, PC, PD, PE, PF *PointerBlock
}

func main() {
	// Disable GC during allocation to speed up setup and ensure dense packing
	debug.SetGCPercent(-1)

	const heapSizeMB = 180 // Fit within 256MB container
	const blockSize = 128
	const numBlocks = (heapSizeMB * 1024 * 1024) / blockSize

	// Pre-allocate slice to avoid resizing
	refs := make([]*PointerBlock, numBlocks)

	// Allocation Loop: Create dense graph
	for i := 0; i < numBlocks; i++ {
		b := &PointerBlock{}
		// Create a chain/graph to ensure liveliness and pointer scanning
		if i > 0 {
			b.P0 = refs[i-1] // Link backward
			b.PF = refs[i/2] // Random-ish backward link
		}
		refs[i] = b
	}

	// Force one GC to stabilize heap state
	runtime.GC()

	// Benchmark Phase
	start := time.Now()
	const cycles = 20
	var totalPause time.Duration

	for i := 0; i < cycles; i++ {
		cycleStart := time.Now()

		// Perform a full GC cycle
		runtime.GC()

		pause := time.Since(cycleStart)
		totalPause += pause

		// Mutate slightly to prevent complete optimization (unlikely but good practice)
		refs[0].P1 = refs[numBlocks-1-i]
	}

	elapsed := time.Since(start)

	// Stats
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	// Calculate efficiency metrics
	gcEfficiency := float64(totalPause.Milliseconds()) / float64(cycles)

	fmt.Printf("RESULT: %.2f,%.2f,%d,%d\n",
		float64(elapsed.Milliseconds()),
		gcEfficiency, // Average pause in ms
		cycles,
		m.Alloc/1024/1024,
	)
}
