
#ifdef CONFIG_SCHED_TUNE

#include <linux/reciprocal_div.h>

/*
 * System energy normalization constants
 */
struct target_nrg {
	unsigned long min_power;
	unsigned long max_power;
	struct reciprocal_value rdiv;
};

int schedtune_cpu_boost_with(int cpu, struct task_struct *p);
int schedtune_task_boost(struct task_struct *tsk);

int schedtune_prefer_idle(struct task_struct *tsk);

/*
 * Identifies threads that directly participate in UI frame delivery.
 * Used to apply extra scheduling priority independent of cgroup membership,
 * since top-app cgroup includes unrelated services (keyboard, cameraserver).
 *
 * Note: task_struct->comm is at most TASK_COMM_LEN-1 (15) chars.
 */
static inline bool is_ui_thread(struct task_struct *p)
{
	const char *comm = p->comm;
	char c = comm[0];

	/* Fast-fail filter: only perform strcmp if first char matches a UI thread name */
	if (c != 'R' && c != 's' && c != 'a' && c != 'H')
		return false;

	return !strcmp(comm, "RenderThread")    ||
	       !strcmp(comm, "RenderEngine")    ||
	       !strcmp(comm, "surfaceflinger")  ||
	       !strcmp(comm, "android.display") ||
	       !strcmp(comm, "android.anim")    ||
	       !strcmp(comm, "android.ui")      ||
	       !strncmp(comm, "HwBinder", 8);
}


void schedtune_enqueue_task(struct task_struct *p, int cpu);
void schedtune_dequeue_task(struct task_struct *p, int cpu);

#else /* CONFIG_SCHED_TUNE */

#define schedtune_cpu_boost_with(cpu, p)  0
#define schedtune_task_boost(tsk) 0

#define schedtune_prefer_idle(tsk) 0

#define schedtune_enqueue_task(task, cpu) do { } while (0)
#define schedtune_dequeue_task(task, cpu) do { } while (0)

#define stune_util(cpu, other_util, walt_load) cpu_util_cfs(cpu_rq(cpu))
#endif /* CONFIG_SCHED_TUNE */
