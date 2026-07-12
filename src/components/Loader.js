"use client";
import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";

export default function Loader({ onComplete }) {
  const [progress, setProgress] = useState(0);
  const [isDone, setIsDone] = useState(false);

  useEffect(() => {
    const duration = 1200; // Fast 1.2s loading
    const intervalTime = 20;
    const step = 100 / (duration / intervalTime);

    const timer = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) {
          clearInterval(timer);
          setTimeout(() => {
            setIsDone(true);
            setTimeout(() => {
              if (onComplete) onComplete();
            }, 500); // Wait for exit animation
          }, 200);
          return 100;
        }
        return prev + step;
      });
    }, intervalTime);

    return () => clearInterval(timer);
  }, [onComplete]);

  return (
    <AnimatePresence>
      {!isDone && (
        <motion.div
          className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-[#050505]"
          initial={{ opacity: 1 }}
          exit={{ opacity: 0, y: -20, transition: { duration: 0.5, ease: [0.76, 0, 0.24, 1] } }}
        >
          {/* Logo Animation */}
          <div className="relative mb-6 overflow-hidden">
            <motion.div
              initial={{ y: 50, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ duration: 0.6, ease: "easeOut" }}
              className="text-center"
            >
              <span className="font-heading text-3xl font-extrabold tracking-tighter text-white">
                PRINCE<span className="text-[#FF2B2B]">.</span>JHA
              </span>
              <p className="font-mono text-[9px] text-[#A3A3A3] tracking-widest uppercase mt-1">
                SYSTEMS OPERATIONAL // v2.0.0
              </p>
            </motion.div>
          </div>

          {/* Progress Bar Container */}
          <div className="w-48 h-[1.5px] bg-white/5 rounded-full overflow-hidden relative">
            <motion.div
              className="h-full bg-[#FF2B2B]"
              style={{ width: `${progress}%` }}
              transition={{ ease: "easeInOut" }}
            />
          </div>

          {/* Percentage */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 0.4 }}
            className="mt-3 font-mono text-[9px] text-[#A3A3A3] tracking-widest"
          >
            BOOT_SEQUENCE_FLOW {Math.min(100, Math.floor(progress))}%
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
