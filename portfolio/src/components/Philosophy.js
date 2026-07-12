"use client";
import { motion } from "framer-motion";
import { User } from "lucide-react";

export default function Philosophy() {
  const statement = "I enjoy building AI-powered products that solve real-world problems using Flutter, Python and modern web technologies.";

  return (
    <section
      id="about"
      className="relative w-full bg-[#050505] py-24 px-6 md:px-12 max-w-5xl mx-auto border-t border-white/5"
    >
      <div className="flex flex-col items-start gap-6 text-left">
        {/* Section Label */}
        <div className="font-mono text-xs uppercase tracking-widest text-[#FF2B2B] flex items-center gap-2">
          <User className="w-4 h-4" />
          <span>About Me</span>
        </div>

        {/* Minimal Large Statement */}
        <div className="max-w-4xl mt-2">
          <h3 className="font-heading text-xl sm:text-2xl md:text-3xl lg:text-4xl font-semibold text-white tracking-tight leading-relaxed">
            {statement.split(" ").map((word, idx) => {
              const isHighlight =
                word.toLowerCase().includes("ai-powered") ||
                word.toLowerCase().includes("solve") ||
                word.toLowerCase().includes("real-world");

              return (
                <motion.span
                  key={idx}
                  initial={{ opacity: 0, y: 15 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true, margin: "-50px" }}
                  transition={{ duration: 0.5, delay: idx * 0.03, ease: "easeOut" }}
                  className={`inline-block mr-[0.25em] ${
                    isHighlight ? "text-[#FF2B2B]" : "text-white"
                  }`}
                >
                  {word}
                </motion.span>
              );
            })}
          </h3>
        </div>
      </div>
    </section>
  );
}
