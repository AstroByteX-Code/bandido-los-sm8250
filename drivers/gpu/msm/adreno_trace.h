/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * Copyright (c) 2013-2019, The Linux Foundation. All rights reserved.
 */

#ifndef _ADRENO_TRACE_H
#define _ADRENO_TRACE_H

struct adreno_device;
struct adreno_context;
struct kgsl_drawobj;
struct kgsl_drawobj_cmd;
struct adreno_ringbuffer;

static inline void trace_kgsl_a3xx_irq_status(struct adreno_device *adreno_dev,
				unsigned int status) {}

static inline void trace_kgsl_a5xx_irq_status(struct adreno_device *adreno_dev,
				unsigned int status) {}

#define trace_adreno_cmdbatch_fault(...) ((void)0)
#define trace_adreno_cmdbatch_queued(...) ((void)0)
#define trace_adreno_cmdbatch_recovery(...) ((void)0)
#define trace_adreno_cmdbatch_retired(...) ((void)0)
#define trace_adreno_cmdbatch_submitted(...) ((void)0)
#define trace_adreno_cmdbatch_sync(...) ((void)0)
#define trace_adreno_drawctxt_invalidate(...) ((void)0)
#define trace_adreno_drawctxt_sleep(...) ((void)0)
#define trace_adreno_drawctxt_switch(...) ((void)0)
#define trace_adreno_drawctxt_wait_done(...) ((void)0)
#define trace_adreno_drawctxt_wait_start(...) ((void)0)
#define trace_adreno_drawctxt_wake(...) ((void)0)
#define trace_adreno_gpu_fault(...) ((void)0)
#define trace_adreno_hw_preempt_comp_to_clear(...) ((void)0)
#define trace_adreno_hw_preempt_token_submit(...) ((void)0)
#define trace_adreno_ifpc_count(...) ((void)0)
#define trace_adreno_preempt_done(...) ((void)0)
#define trace_adreno_preempt_trigger(...) ((void)0)
#define trace_adreno_sp_tp(...) ((void)0)
#define trace_dispatch_queue_context(...) ((void)0)
#define trace_adreno_hw_preempt_clear_to_trig(...) ((void)0)
#define trace_adreno_hw_preempt_trig_to_comp(...) ((void)0)
#define trace_adreno_hw_preempt_trig_to_comp_int(...) ((void)0)

#endif /* _ADRENO_TRACE_H */
