"use client";
import { useState } from "react";
import { Send, Mail, Linkedin, Github, FileText, CheckCircle2, ArrowRight, Sparkles } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

export default function Contact() {
  const [formData, setFormData] = useState({ name: "", email: "", message: "" });
  const [status, setStatus] = useState("idle"); // 'idle', 'submitting', 'success'
  const [errors, setErrors] = useState({});

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: null }));
    }
  };

  const validateForm = () => {
    const newErrors = {};
    if (!formData.name.trim()) newErrors.name = "Name is required.";
    if (!formData.email.trim()) {
      newErrors.email = "Email is required.";
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = "Invalid email format.";
    }
    if (!formData.message.trim() || formData.message.length < 5) {
      newErrors.message = "Message must be at least 5 characters.";
    }
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    setStatus("submitting");

    // Simulate database transmission delay
    setTimeout(() => {
      setStatus("success");
      setFormData({ name: "", email: "", message: "" });
    }, 1500);
  };

  const channels = [
    { name: "Email Address", val: "princejha.work@gmail.com", href: "mailto:princejha.work@gmail.com", icon: <Mail className="w-5 h-5 text-[#FF2B2B]" /> },
    { name: "LinkedIn Profile", val: "linkedin.com/in/prince-jha-7a26a3303", href: "https://www.linkedin.com/in/prince-jha-7a26a3303", icon: <Linkedin className="w-5 h-5 text-white/80" /> },
    { name: "GitHub Profile", val: "github.com/Princejha10", href: "https://github.com/Princejha10", icon: <Github className="w-5 h-5 text-white/80" /> },
    { name: "Curriculum Vitae", val: "Download PDF Resume", href: "/resume.pdf", icon: <FileText className="w-5 h-5 text-white/80" /> }
  ];

  return (
    <section id="contact" className="py-24 px-6 md:px-12 max-w-5xl mx-auto w-full relative border-t border-white/5 bg-[#050505]">
      
      {/* Grid Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-16 items-start">
        
        {/* Left Column: CTA & Details */}
        <div className="lg:col-span-5 text-left flex flex-col gap-6">
          <div className="font-mono text-xs uppercase tracking-widest text-[#FF2B2B] flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-[#FF2B2B]" />
            <span>Connection Gateway</span>
          </div>

          <h2 className="font-heading text-3xl md:text-5xl font-extrabold text-white tracking-tight uppercase leading-none">
            Let's Connect
          </h2>

          <p className="font-sans text-xs md:text-sm text-[#A3A3A3] leading-relaxed max-w-md">
            I am always open to discussing new opportunities, collaboration on open-source AI configurations, or Flutter client-side architectures.
          </p>

          {/* Channels Grid */}
          <div className="space-y-3 pt-6 border-t border-white/5">
            {channels.map((chan) => (
              <a
                key={chan.name}
                href={chan.href}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-4 bg-[#111111] border border-white/5 rounded-2xl p-4 hover:border-[#FF2B2B]/20 transition-all group"
              >
                <div className="p-2 bg-[#050505] rounded-xl border border-white/5 shrink-0">
                  {chan.icon}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-[9px] font-mono text-white/40 uppercase tracking-wider">{chan.name}</div>
                  <div className="text-xs font-semibold text-white truncate group-hover:text-[#FF2B2B] transition-colors">
                    {chan.val}
                  </div>
                </div>
                <ArrowRight className="w-4 h-4 text-white/20 group-hover:text-[#FF2B2B] transition-transform group-hover:translate-x-1" />
              </a>
            ))}
          </div>
        </div>

        {/* Right Column: Minimal Form */}
        <div className="lg:col-span-7 w-full">
          <div className="bg-[#111111] rounded-[2rem] border border-white/5 p-6 md:p-10 relative overflow-hidden">
            
            <AnimatePresence mode="wait">
              {status === "success" ? (
                /* Success Feedback */
                <motion.div
                  key="success"
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0 }}
                  className="flex flex-col items-center justify-center py-12 text-center space-y-4"
                >
                  <div className="p-4 rounded-full bg-[#10B981]/10 text-[#10B981] border border-[#10B981]/20">
                    <CheckCircle2 className="w-10 h-10" />
                  </div>

                  <div className="space-y-1">
                    <h3 className="font-heading text-xl font-bold text-white uppercase tracking-tight">
                      Transmission Ingested
                    </h3>
                    <p className="font-sans text-xs text-[#A3A3A3] max-w-xs">
                      Your message cleared routing checks. Prince will respond within 24 hours.
                    </p>
                  </div>

                  <button
                    onClick={() => setStatus("idle")}
                    className="magnetic-btn group border border-white/10 hover:border-white/20 text-xs font-heading font-medium tracking-wide py-2.5 px-6 rounded-full flex items-center justify-center gap-1.5 mt-6 text-white transition-all"
                  >
                    Send Another Message
                  </button>
                </motion.div>
              ) : (
                /* Form fields */
                <motion.form
                  key="form"
                  onSubmit={handleSubmit}
                  initial={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  className="space-y-5 text-left"
                >
                  <div className="space-y-2">
                    <label className="font-mono text-[9px] text-[#A3A3A3] uppercase tracking-widest block">
                      Name
                    </label>
                    <input
                      type="text"
                      name="name"
                      value={formData.name}
                      onChange={handleInputChange}
                      disabled={status === "submitting"}
                      className={`w-full bg-[#050505] border rounded-xl px-4 py-3 text-xs font-sans text-white focus:outline-none focus:border-[#FF2B2B] transition-colors ${
                        errors.name ? "border-[#FF2B2B]" : "border-white/5"
                      }`}
                      placeholder="Your name"
                    />
                    {errors.name && (
                      <p className="font-mono text-[9px] text-[#FF2B2B] mt-1">{errors.name}</p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <label className="font-mono text-[9px] text-[#A3A3A3] uppercase tracking-widest block">
                      Email
                    </label>
                    <input
                      type="email"
                      name="email"
                      value={formData.email}
                      onChange={handleInputChange}
                      disabled={status === "submitting"}
                      className={`w-full bg-[#050505] border rounded-xl px-4 py-3 text-xs font-sans text-white focus:outline-none focus:border-[#FF2B2B] transition-colors ${
                        errors.email ? "border-[#FF2B2B]" : "border-white/5"
                      }`}
                      placeholder="Your email"
                    />
                    {errors.email && (
                      <p className="font-mono text-[9px] text-[#FF2B2B] mt-1">{errors.email}</p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <label className="font-mono text-[9px] text-[#A3A3A3] uppercase tracking-widest block">
                      Message
                    </label>
                    <textarea
                      name="message"
                      rows="4"
                      value={formData.message}
                      onChange={handleInputChange}
                      disabled={status === "submitting"}
                      className={`w-full bg-[#050505] border rounded-xl px-4 py-3 text-xs font-sans text-white focus:outline-none focus:border-[#FF2B2B] transition-colors resize-none ${
                        errors.message ? "border-[#FF2B2B]" : "border-white/5"
                      }`}
                      placeholder="Write your message here..."
                    />
                    {errors.message && (
                      <p className="font-mono text-[9px] text-[#FF2B2B] mt-1">{errors.message}</p>
                    )}
                  </div>

                  {/* Submit */}
                  <button
                    type="submit"
                    disabled={status === "submitting"}
                    className="magnetic-btn group bg-[#FF2B2B] text-white text-xs font-heading font-medium tracking-widest uppercase py-3.5 px-6 rounded-full flex items-center justify-center gap-2 shadow-[0_0_20px_rgba(255,43,43,0.15)] w-full transition-all"
                  >
                    <span className="z-10 flex items-center gap-2">
                      {status === "submitting" ? "Transmitting..." : "Transmit Message"}
                      <Send className="w-3.5 h-3.5" />
                    </span>
                  </button>
                </motion.form>
              )}
            </AnimatePresence>

          </div>
        </div>

      </div>
    </section>
  );
}
