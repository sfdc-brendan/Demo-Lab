#!/usr/bin/env node
/**
 * Writes the demo logs into sample-logs/.
 *
 * These are generated rather than checked in by hand because the interesting part
 * is the volume: a real driver log buries a dozen meaningful lines under thousands
 * of INFO records and repeated retries, and that ratio is exactly what the
 * distiller exists to handle. A hand-written 40-line log would not exercise it.
 *
 * Usage: node scripts/generateSampleLogs.js
 */
const fs = require("fs");
const path = require("path");

const OUT_DIR = path.resolve(__dirname, "..", "sample-logs");

let clock = Date.UTC(2026, 6, 14, 2, 11, 4);

function stamp(advanceMs = 40) {
  clock += advanceMs;
  const d = new Date(clock);
  const p = (n, w = 2) => String(n).padStart(w, "0");
  return `${p(d.getUTCFullYear() % 100)}/${p(d.getUTCMonth() + 1)}/${p(d.getUTCDate())} ${p(
    d.getUTCHours()
  )}:${p(d.getUTCMinutes())}:${p(d.getUTCSeconds())}`;
}

function line(level, logger, message, advanceMs) {
  return `${stamp(advanceMs)} ${level} ${logger}: ${message}`;
}

function pick(seed, options) {
  return options[seed % options.length];
}

/** Cluster startup preamble, common to every log. */
function preamble(clusterId, runtime, nodeType, workers) {
  return [
    line("INFO", "DriverDaemon", `Starting Lakehouse Runtime ${runtime}`),
    line("INFO", "DriverDaemon", `Cluster id: ${clusterId}`),
    line("INFO", "DriverDaemon", `Driver node type: ${nodeType}`),
    line(
      "INFO",
      "DriverDaemon",
      `Worker node type: ${nodeType}, workers: ${workers}`
    ),
    line("INFO", "DriverDaemon", "Spark version: 3.5.0"),
    line("INFO", "DriverDaemon", "Scala version: 2.12.18"),
    line("INFO", "DriverDaemon", "Python version: 3.10.12"),
    line("INFO", "DriverDaemon", "Photon enabled: true"),
    line("INFO", "SparkContext", "Running Spark version 3.5.0"),
    line(
      "INFO",
      "ResourceUtils",
      "No custom resources configured for spark.driver."
    ),
    line("INFO", "SecurityManager", "Changing view acls to: root,spark"),
    line(
      "INFO",
      "Utils",
      "Successfully started service sparkDriver on port 40213."
    ),
    line("INFO", "SparkEnv", "Registering MapOutputTracker"),
    line("INFO", "SparkEnv", "Registering BlockManagerMaster"),
    line(
      "INFO",
      "DiskBlockManager",
      "Created local directory at /local_disk0/blockmgr-8f21"
    ),
    line("INFO", "MemoryStore", "MemoryStore started with capacity 22.4 GiB"),
    line("INFO", "SparkEnv", "Registering OutputCommitCoordinator"),
    line(
      "INFO",
      "Utils",
      "Successfully started service SparkUI on port 40001."
    ),
    line("INFO", "StandaloneSchedulerBackend", "Connected to Spark cluster"),
    line("INFO", "SharedState", "Warehouse path is dbfs:/user/hive/warehouse"),
    line(
      "INFO",
      "UnityCatalogClient",
      "Unity Catalog enabled, metastore: 8a3f-prod-us-east-1"
    ),
    line("INFO", "HiveConf", "Found configuration file null")
  ];
}

/** Steady-state task chatter used to bury the signal. */
function taskNoise(count, stageId, startTask) {
  const out = [];
  for (let i = 0; i < count; i++) {
    const task = startTask + i;
    const executor = (i % 8) + 1;
    const host = `10.139.64.${(i % 8) + 12}`;
    out.push(
      line(
        "INFO",
        "TaskSetManager",
        `Starting task ${task}.0 in stage ${stageId}.0 (TID ${task}, ${host}, executor ${executor}, partition ${task}, PROCESS_LOCAL, 4821 bytes)`,
        12
      )
    );
    out.push(
      line(
        "INFO",
        "Executor",
        `Finished task ${task}.0 in stage ${stageId}.0 (TID ${task}). ${
          2100 + (task % 900)
        } bytes result sent to driver`,
        8
      )
    );
    if (i % 5 === 0) {
      out.push(
        line(
          "INFO",
          "BlockManagerInfo",
          `Added broadcast_${stageId}_piece0 in memory on ${host}:41${
            (i % 90) + 10
          } (size: 34.2 KiB, free: 18.1 GiB)`,
          6
        )
      );
    }
    if (i % 13 === 0) {
      out.push(
        line(
          "INFO",
          "FileScanRDD",
          `Reading File path: s3://acme-lakehouse/bronze/events/date=2026-07-${
            (i % 28) + 1
          }/part-${String(i).padStart(5, "0")}.snappy.parquet, range: 0-134217728`,
          5
        )
      );
    }
    if (i % 29 === 0) {
      out.push(
        line(
          "INFO",
          "CodeGenerator",
          `Code generated in ${12 + (i % 40)}.${i % 10} ms`,
          4
        )
      );
    }
  }
  return out;
}

function stageBoundary(stageId, description, taskCount) {
  return [
    line(
      "INFO",
      "DAGScheduler",
      `Submitting ${taskCount} missing tasks from ShuffleMapStage ${stageId} (${description})`
    ),
    line(
      "INFO",
      "TaskSchedulerImpl",
      `Adding task set ${stageId}.0 with ${taskCount} tasks`
    ),
    line(
      "INFO",
      "MemoryStore",
      `Block broadcast_${stageId} stored as values in memory (estimated size 412.1 KiB)`
    )
  ];
}

// ---------------------------------------------------------------------------
// 1. Driver OOM -> KB-001
// ---------------------------------------------------------------------------
function driverOom() {
  clock = Date.UTC(2026, 6, 14, 2, 11, 4);
  const out = preamble("0714-021104-mvpq3z8k", "14.3 LTS", "r5d.4xlarge", 8);

  out.push(
    line(
      "INFO",
      "DriverCorral",
      "Attaching notebook /Users/dana.kim@acme.com/quarterly_rollup"
    )
  );
  out.push(line("INFO", "ProgressReporter", "Command started: cell 1"));
  out.push(
    ...stageBoundary(
      3,
      "MapPartitionsRDD[14] at toPandas at command-4471:8",
      1200
    )
  );
  out.push(...taskNoise(420, 3, 0));

  out.push(
    line("INFO", "DAGScheduler", "ShuffleMapStage 3 finished in 184.221 s")
  );
  out.push(...stageBoundary(4, "collect at command-4471:8", 1200));
  out.push(...taskNoise(300, 4, 1200));

  out.push(
    line(
      "INFO",
      "TaskSetManager",
      "Finished task 1499.0 in stage 4.0 (TID 2699) in 812 ms"
    )
  );
  out.push(
    line(
      "INFO",
      "DAGScheduler",
      "ResultStage 4 (collect at command-4471:8) finished in 96.418 s"
    )
  );
  out.push(
    line(
      "INFO",
      "ArrowConverters",
      "Collecting 1,204,881,332 rows to the driver for toPandas conversion"
    )
  );

  // GC death spiral: the same line thousands of times, which is the point.
  for (let i = 0; i < 1400; i++) {
    const used = 27100 + (i % 60);
    out.push(
      `${stamp(30)} [Full GC (Allocation Failure)  ${used}M->${
        used - 8 + (i % 5)
      }M(28160M), ${9 + (i % 6)}.${(i * 7) % 10}${(i * 3) % 10}41230 secs]`
    );
    if (i % 200 === 0) {
      out.push(
        line(
          "WARN",
          "HeartbeatReceiver",
          "Removing executor 3 with no recent heartbeats: 152418 ms exceeds timeout 120000 ms",
          20
        )
      );
    }
  }

  out.push(
    line("ERROR", "Executor", "Exception in task 0.0 in stage 5.0 (TID 2700)")
  );
  out.push("java.lang.OutOfMemoryError: Java heap space");
  out.push("\tat java.base/java.util.Arrays.copyOf(Arrays.java:3537)");
  out.push(
    "\tat org.apache.arrow.vector.BaseValueVector.reAlloc(BaseValueVector.java:184)"
  );
  out.push(
    "\tat org.apache.spark.sql.execution.arrow.ArrowConverters$.toBatchIterator(ArrowConverters.scala:214)"
  );
  out.push(
    "\tat org.apache.spark.sql.Dataset.$anonfun$collectAsArrowToPython$1(Dataset.scala:3891)"
  );
  out.push("\tat org.apache.spark.sql.Dataset.withAction(Dataset.scala:4197)");
  out.push(
    "\tat com.lakehouse.backend.daemon.driver.PythonDriverLocal.repl(PythonDriverLocal.scala:722)"
  );
  out.push(
    "\tat com.lakehouse.backend.daemon.driver.DriverLocal.execute(DriverLocal.scala:668)"
  );
  out.push("\tat java.base/java.lang.Thread.run(Thread.java:840)");

  out.push(
    line(
      "ERROR",
      "SparkContext",
      "Error initializing SparkContext after driver heap exhaustion"
    )
  );
  out.push(
    line(
      "ERROR",
      "DriverDaemon",
      "Fatal error: The Spark driver has stopped unexpectedly and is restarting."
    )
  );
  out.push(
    line(
      "WARN",
      "DriverCorral",
      "Notebook /Users/dana.kim@acme.com/quarterly_rollup detached"
    )
  );
  out.push(
    line(
      "INFO",
      "DriverDaemon",
      "Driver is up but is not responsive, likely due to GC."
    )
  );
  out.push(
    line("INFO", "LakehouseMain", "Shutting down driver JVM, exit code 52")
  );

  return out.join("\n") + "\n";
}

// ---------------------------------------------------------------------------
// 2. Unity Catalog permission denied -> KB-004
// ---------------------------------------------------------------------------
function unityCatalogDenied() {
  clock = Date.UTC(2026, 6, 15, 9, 3, 22);
  const out = preamble("0715-090322-hb4tn19w", "15.4 LTS", "i3.2xlarge", 4);

  out.push(
    line(
      "INFO",
      "JobRunner",
      'Starting job run 884213 for job "nightly-revenue-refresh"'
    )
  );
  out.push(line("INFO", "JobRunner", "Run as user: svc-etl-prod@acme.com"));
  out.push(line("INFO", "ClusterConfig", "Access mode: SINGLE_USER"));
  out.push(line("INFO", "UnityCatalogClient", "Resolving catalog main"));
  out.push(...stageBoundary(1, "Scan parquet main.finance.dim_account", 240));
  out.push(...taskNoise(180, 1, 0));
  out.push(
    line("INFO", "DAGScheduler", "ShuffleMapStage 1 finished in 42.118 s")
  );

  out.push(
    line(
      "INFO",
      "UnityCatalogClient",
      "Resolving table main.sales.transactions"
    )
  );
  for (let i = 0; i < 6; i++) {
    out.push(
      line(
        "WARN",
        "UnityCatalogClient",
        `Retrying metadata request for main.sales.transactions (attempt ${i + 1}/6) after PERMISSION_DENIED`,
        900
      )
    );
  }

  out.push(
    line(
      "ERROR",
      "UnityCatalogClient",
      "Metadata request failed for main.sales.transactions"
    )
  );
  out.push(
    line("ERROR", "ScalaDriverLocal", "User Code Exception in job run 884213")
  );
  out.push(
    "org.apache.spark.sql.AnalysisException: [INSUFFICIENT_PERMISSIONS] Insufficient privileges:"
  );
  out.push(
    "User does not have permission SELECT on table 'main.sales.transactions'. SQLSTATE: 42501"
  );
  out.push(
    "\tat org.apache.spark.sql.errors.QueryCompilationErrors$.insufficientPermissionsError(QueryCompilationErrors.scala:3812)"
  );
  out.push(
    "\tat com.lakehouse.sql.managedcatalog.ManagedCatalogClientImpl.getTable(ManagedCatalogClientImpl.scala:1204)"
  );
  out.push(
    "\tat com.lakehouse.sql.managedcatalog.ManagedCatalogCommon.loadTable(ManagedCatalogCommon.scala:451)"
  );
  out.push(
    "\tat com.lakehouse.sql.CatalogManager.loadTable(CatalogManager.scala:118)"
  );
  out.push(
    "\tat org.apache.spark.sql.catalyst.analysis.Analyzer$ResolveRelations.resolveRelation(Analyzer.scala:1287)"
  );
  out.push(
    "\tat org.apache.spark.sql.Dataset.$anonfun$sql$1(Dataset.scala:112)"
  );
  out.push("\tat java.base/java.lang.Thread.run(Thread.java:840)");
  out.push(
    "Caused by: com.lakehouse.managedcatalog.UCPermissionDeniedException: PERMISSION_DENIED:"
  );
  out.push("User does not have USE SCHEMA on Schema 'main.sales'");
  out.push(
    "\tat com.lakehouse.managedcatalog.ErrorDetailsHandler.wrapServiceException(ErrorDetailsHandler.scala:41)"
  );
  out.push(
    "\tat com.lakehouse.managedcatalog.ManagedCatalogClientImpl.recordAndWrapException(ManagedCatalogClientImpl.scala:5211)"
  );

  out.push(
    line(
      "ERROR",
      "JobRunner",
      "Job run 884213 failed with state INTERNAL_ERROR"
    )
  );
  out.push(
    line("INFO", "JobRunner", "Terminating cluster 0715-090322-hb4tn19w")
  );

  return out.join("\n") + "\n";
}

// ---------------------------------------------------------------------------
// 3. Delta concurrent write conflict -> KB-005
// ---------------------------------------------------------------------------
function deltaWriteConflict() {
  clock = Date.UTC(2026, 6, 16, 23, 45, 8);
  const out = preamble("0716-234508-qq71dx4p", "14.3 LTS", "m5d.2xlarge", 6);

  out.push(
    line(
      "INFO",
      "MicroBatchExecution",
      "Starting streaming query id = 7c19a4f2-3b88-4d1e-9a02-11c4e6f0b533"
    )
  );
  out.push(
    line(
      "INFO",
      "MicroBatchExecution",
      "Checkpoint root: s3://acme-lakehouse/_checkpoints/silver_orders"
    )
  );
  out.push(
    line(
      "INFO",
      "DeltaLog",
      "Loading version 41822 of s3://acme-lakehouse/silver/orders"
    )
  );

  for (let batch = 4810; batch < 4818; batch++) {
    out.push(
      line(
        "INFO",
        "MicroBatchExecution",
        `Streaming query made progress: batch ${batch}, 18422 rows`,
        200
      )
    );
    out.push(
      ...stageBoundary(
        batch % 40,
        `MERGE INTO silver.orders at command-991:4`,
        200
      )
    );
    out.push(...taskNoise(90, batch % 40, batch * 200));
    out.push(
      line(
        "INFO",
        "DeltaLog",
        `Committed transaction, version ${41822 + (batch - 4810)}`,
        60
      )
    );
  }

  // The competing batch job, retrying against the same partition.
  for (let attempt = 1; attempt <= 5; attempt++) {
    out.push(
      line(
        "WARN",
        "OptimisticTransaction",
        `Transaction conflict detected on s3://acme-lakehouse/silver/orders, retrying (attempt ${attempt}/5)`,
        1500
      )
    );
    out.push(
      line(
        "WARN",
        "DeltaLog",
        "Concurrent update detected while committing; reloading snapshot at version " +
          (41830 + attempt),
        300
      )
    );
  }

  out.push(
    line(
      "ERROR",
      "MicroBatchExecution",
      "Query [id = 7c19a4f2-3b88-4d1e-9a02-11c4e6f0b533] terminated with error"
    )
  );
  out.push(
    "io.delta.exceptions.ConcurrentAppendException: Files were added to partition [order_date=2026-07-16] by a concurrent update. Please try the operation again."
  );
  out.push(
    'Conflicting commit: {"timestamp":1789523108441,"userId":"3049128841","userName":"svc-batch-recon@acme.com","operation":"MERGE","operationParameters":{"predicate":"(target.order_id = source.order_id)"},"readVersion":41829,"isBlindAppend":false}'
  );
  out.push(
    "Refer to https://docs.lakehouse.example.com/delta/concurrency-control.html for more details."
  );
  out.push(
    "\tat io.delta.exceptions.DeltaConcurrentModificationException.<init>(DeltaErrors.scala:2891)"
  );
  out.push(
    "\tat org.apache.spark.sql.delta.OptimisticTransactionImpl.checkForAddedFilesThatShouldHaveBeenReadByCurrentTxn(OptimisticTransaction.scala:1842)"
  );
  out.push(
    "\tat org.apache.spark.sql.delta.OptimisticTransactionImpl.checkAndRetry(OptimisticTransaction.scala:1701)"
  );
  out.push(
    "\tat org.apache.spark.sql.delta.OptimisticTransactionImpl.doCommit(OptimisticTransaction.scala:1402)"
  );
  out.push(
    "\tat org.apache.spark.sql.delta.commands.MergeIntoCommand.run(MergeIntoCommand.scala:388)"
  );
  out.push(
    "\tat org.apache.spark.sql.execution.streaming.MicroBatchExecution.runBatch(MicroBatchExecution.scala:812)"
  );
  out.push("\tat java.base/java.lang.Thread.run(Thread.java:840)");

  out.push(
    line(
      "ERROR",
      "StreamExecution",
      "Stream terminated after 8 successful batches; last committed version 41829"
    )
  );
  out.push(
    line(
      "WARN",
      "JobRunner",
      'Streaming job "silver-orders-merge" entered FAILED state and will not auto-restart'
    )
  );

  return out.join("\n") + "\n";
}

const files = {
  "driver-oom-cluster-0714.log": driverOom(),
  "unity-catalog-permission-denied-run-884213.log": unityCatalogDenied(),
  "delta-concurrent-write-silver-orders.log": deltaWriteConflict()
};

fs.mkdirSync(OUT_DIR, { recursive: true });
for (const [name, body] of Object.entries(files)) {
  fs.writeFileSync(path.join(OUT_DIR, name), body);
  const lines = body.split("\n").length - 1;
  console.log(`${name}  ${lines} lines  ${(body.length / 1024).toFixed(0)} KB`);
}
