"use client";
import { useState } from "react";
import { Briefcase, GraduationCap, Award, ExternalLink, Calendar, Star, ChevronRight, Sparkles } from "lucide-react";
import { motion } from "framer-motion";

export default function ExperienceEducation() {
  const [activeTab, setActiveTab] = useState("exp"); // 'exp' or 'certs'

  const experiences = [
    {
      role: "IT Intern",
      company: "Airports Authority of India (AAI)",
      period: "Jun 2025 - Aug 2025",
      desc: "Assisted the Information Technology department with database networks and systems audit.",
      details: [
        "Analyzed database traffic logs to monitor anomalies, ensuring integrity of systems logs.",
        "Created parsing scripts in Python to automate the aggregation and clean up of networking reports.",
        "Assisted in configuring access management protocols, troubleshooting database connectivity spikes."
      ],
      tech: ["Python", "SQLite", "Excel Automation", "Network Auditing"],
      achievements: "Built an automated parser script replacing manual Excel formatting workflows for logs audits."
    }
  ];

  const education = [
    {
      degree: "B.Tech in Computer Science & Engineering",
      institution: "Technological University",
      period: "2022 - 2026",
      coursework: ["Database Management Systems", "Computer Networks", "Operating Systems", "Python Programming"],
      achievements: "Graduating with a CGPA of 7.5. Developed multiple automation projects including FinSense."
    }
  ];

  const certifications = [
    {
      title: "Flutter Advanced State Management & Architecture",
      provider: "Udemy",
      date: "May 2025",
      link: "https://udemy.com/certificate/flutter-adv",
    },
    {
      title: "Python for Data Analysis & Automation",
      provider: "Coursera",
      date: "Jul 2025",
      link: "https://coursera.org/verify/python-data",
    }
  ];

  return (
    <section id="experience" className="py-24 px-6 md:px-12 max-w-5xl mx-auto w-full relative border-t border-white/5 bg-[#050505]">
      
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-16">
        <div className="flex flex-col items-start gap-4 text-left">
          <div className="font-mono text-xs uppercase tracking-widest text-[#FF2B2B] flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-[#FF2B2B]" />
            <span>Career Milestones</span>
          </div>
          <h2 className="font-heading text-2xl md:text-3xl font-bold tracking-tight text-white uppercase">
            Experience & Education
          </h2>
        </div>

        {/* Tab triggers */}
        <div className="flex bg-white/5 border border-white/5 p-1 rounded-xl self-start md:self-end">
          <button
            onClick={() => setActiveTab("exp")}
            className={`px-4 py-2 rounded-lg text-xs font-heading font-medium tracking-wide uppercase transition-all ${
              activeTab === "exp" ? "bg-[#FF2B2B] text-white" : "text-[#A3A3A3] hover:text-white"
            }`}
          >
            Work & Education
          </button>
          <button
            onClick={() => setActiveTab("certs")}
            className={`px-4 py-2 rounded-lg text-xs font-heading font-medium tracking-wide uppercase transition-all ${
              activeTab === "certs" ? "bg-[#FF2B2B] text-white" : "text-[#A3A3A3] hover:text-white"
            }`}
          >
            Certifications
          </button>
        </div>
      </div>

      {/* Tab Panels */}
      <div className="min-h-[360px]">
        {activeTab === "exp" ? (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
            {/* Experience timeline */}
            <div className="space-y-8 text-left">
              <h3 className="font-heading text-base font-bold text-white uppercase tracking-wider flex items-center gap-2 mb-6">
                <Briefcase className="w-5 h-5 text-[#FF2B2B]" /> Professional Experience
              </h3>

              {experiences.map((exp, idx) => (
                <div
                  key={idx}
                  className="bg-[#111111] rounded-[2rem] p-6 md:p-8 border border-white/5 relative group hover:border-[#FF2B2B]/20 transition-all"
                >
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-4">
                    <div>
                      <h4 className="font-heading text-base font-bold text-white group-hover:text-[#FF2B2B] transition-colors uppercase tracking-tight">
                        {exp.role}
                      </h4>
                      <span className="font-sans text-xs text-[#A3A3A3]">{exp.company}</span>
                    </div>
                    <div className="flex items-center gap-1.5 font-mono text-[9px] text-[#FF2B2B] bg-[#FF2B2B]/5 px-3 py-1 rounded-full border border-[#FF2B2B]/10 self-start sm:self-center">
                      <Calendar className="w-3.5 h-3.5" /> {exp.period}
                    </div>
                  </div>

                  {/* Bullet Points */}
                  <ul className="space-y-2 mb-6 text-xs text-[#A3A3A3] leading-relaxed">
                    {exp.details.map((bullet, bIdx) => (
                      <li key={bIdx} className="flex items-start gap-2">
                        <ChevronRight className="w-4 h-4 text-[#FF2B2B] shrink-0 mt-0.5" />
                        <span>{bullet}</span>
                      </li>
                    ))}
                  </ul>

                  {/* Highlights and Tech */}
                  <div className="space-y-4 pt-4 border-t border-white/5">
                    <div className="flex items-start gap-2 text-xs">
                      <Star className="w-4 h-4 text-[#10B981] shrink-0 mt-0.5" />
                      <p className="text-white/80 leading-relaxed font-sans">
                        <strong className="text-[#10B981]">Core Output:</strong> {exp.achievements}
                      </p>
                    </div>

                    <div className="flex flex-wrap gap-1.5">
                      {exp.tech.map((t) => (
                        <span
                          key={t}
                          className="font-mono text-[9px] text-[#A3A3A3] px-2 py-0.5 bg-white/5 rounded border border-white/5"
                        >
                          {t}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Education timeline */}
            <div className="space-y-8 text-left">
              <h3 className="font-heading text-base font-bold text-white uppercase tracking-wider flex items-center gap-2 mb-6">
                <GraduationCap className="w-5 h-5 text-[#FF2B2B]" /> Education
              </h3>

              {education.map((edu, idx) => (
                <div
                  key={idx}
                  className="bg-[#111111] rounded-[2rem] p-6 md:p-8 border border-white/5 relative group hover:border-[#FF2B2B]/20 transition-all"
                >
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-4">
                    <div>
                      <h4 className="font-heading text-base font-bold text-white group-hover:text-[#FF2B2B] transition-colors uppercase tracking-tight">
                        {edu.degree}
                      </h4>
                      <span className="font-sans text-xs text-[#A3A3A3]">{edu.institution}</span>
                    </div>
                    <div className="flex items-center gap-1.5 font-mono text-[9px] text-[#FF2B2B] bg-[#FF2B2B]/5 px-3 py-1 rounded-full border border-[#FF2B2B]/10 self-start sm:self-center">
                      <Calendar className="w-3.5 h-3.5" /> {edu.period}
                    </div>
                  </div>

                  <p className="font-sans text-xs text-[#A3A3A3] leading-relaxed mb-6">
                    {edu.achievements}
                  </p>

                  <div className="space-y-2 pt-4 border-t border-white/5">
                    <span className="font-mono text-[8px] text-[#A3A3A3] uppercase tracking-wider">
                      RELEVANT MODULES
                    </span>
                    <div className="flex flex-wrap gap-1.5">
                      {edu.coursework.map((course) => (
                        <span
                          key={course}
                          className="font-mono text-[9px] text-white/70 px-2 py-0.5 bg-white/5 rounded border border-white/5"
                        >
                          {course}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        ) : (
          /* Certifications Grid */
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-left">
            {certifications.map((cert, idx) => (
              <motion.div
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.4, delay: idx * 0.05 }}
                key={idx}
                className="bg-[#111111] rounded-[2rem] p-6 border border-white/5 flex flex-col justify-between group hover:border-[#FF2B2B]/20 transition-all"
              >
                <div>
                  <div className="flex justify-between items-center mb-6">
                    <div className="p-2.5 rounded-2xl bg-white/5 text-[#FF2B2B]">
                      <Award className="w-5 h-5" />
                    </div>
                    <span className="font-mono text-[9px] text-white/40">{cert.date}</span>
                  </div>

                  <h4 className="font-heading text-base font-bold text-white mb-2 tracking-tight group-hover:text-[#FF2B2B] transition-colors leading-snug uppercase">
                    {cert.title}
                  </h4>
                  <span className="font-sans text-xs text-[#A3A3A3]">{cert.provider}</span>
                </div>

                <div className="pt-6 mt-6 border-t border-white/5 flex justify-end">
                  <a
                    href={cert.link}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-1 text-[9px] font-mono text-[#FF2B2B] hover:text-white transition-colors"
                  >
                    VERIFY CREDENTIAL <ExternalLink className="w-3 h-3" />
                  </a>
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </div>
    </section>
  );
}
