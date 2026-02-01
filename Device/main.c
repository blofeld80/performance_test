#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>
#include <zephyr/sys/util.h>
#include <zephyr/sys_clock.h>

#define STACK_SIZE 1024
#define THREAD_PRIORITY 1

/* Number of ping-pong iterations
 * Total context switches = ITERATIONS * 2
 */
#define ITERATIONS 10000

K_THREAD_STACK_DEFINE(stack_a, STACK_SIZE);
K_THREAD_STACK_DEFINE(stack_b, STACK_SIZE);

static struct k_thread thread_a;
static struct k_thread thread_b;

static struct k_sem sem_a;
static struct k_sem sem_b;

static volatile uint32_t start_cycles;
static volatile uint32_t end_cycles;

void thread_fn_a(void *p1, void *p2, void *p3)
{
    ARG_UNUSED(p1);
    ARG_UNUSED(p2);
    ARG_UNUSED(p3);

    /* Wait for start signal */
    k_sem_take(&sem_a, K_FOREVER);

    start_cycles = k_cycle_get_32();

    for (int i = 0; i < ITERATIONS; i++) {
        k_sem_give(&sem_b);
        k_sem_take(&sem_a, K_FOREVER);
    }

    end_cycles = k_cycle_get_32();
}

void thread_fn_b(void *p1, void *p2, void *p3)
{
    ARG_UNUSED(p1);
    ARG_UNUSED(p2);
    ARG_UNUSED(p3);

    for (;;) {
        k_sem_take(&sem_b, K_FOREVER);
        k_sem_give(&sem_a);
    }
}

int main(void)
{
    uint32_t total_cycles;
    uint32_t cycles_per_switch;
    uint32_t cpu_freq;

    printk("\n=== Zephyr Context Switch Benchmark ===\n");

    k_sem_init(&sem_a, 0, 1);
    k_sem_init(&sem_b, 0, 1);

    k_thread_create(&thread_a, stack_a, STACK_SIZE,
                    thread_fn_a,
                    NULL, NULL, NULL,
                    THREAD_PRIORITY, 0, K_NO_WAIT);

    k_thread_create(&thread_b, stack_b, STACK_SIZE,
                    thread_fn_b,
                    NULL, NULL, NULL,
                    THREAD_PRIORITY, 0, K_NO_WAIT);

    /* Let threads start */
    k_sleep(K_MSEC(100));

    /* Kick off the test */
    k_sem_give(&sem_a);

    /* Wait until test completes */
    while (end_cycles == 0) {
        k_sleep(K_MSEC(1));
    }

    total_cycles = end_cycles - start_cycles;

    /* Each loop iteration causes 2 context switches */
    cycles_per_switch = total_cycles / (ITERATIONS * 2);

    cpu_freq = sys_clock_hw_cycles_per_sec();

    printk("Iterations           : %d\n", ITERATIONS);
    printk("Total cycles         : %u\n", total_cycles);
    printk("Cycles per switch    : %u\n", cycles_per_switch);
    printk("CPU frequency (Hz)   : %u\n", cpu_freq);

    uint32_t ns_per_cycle = 1000000000ULL / cpu_freq;
    printk("Time per switch (ns) : %u\n",
           cycles_per_switch * ns_per_cycle);

    printk("=====================================\n");

    return 0;
}
