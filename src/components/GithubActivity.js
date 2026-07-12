"use client";
import { useEffect, useState } from "react";
import { Github, Star, GitFork, Users, BookOpen, Layers } from "lucide-react";

const FALLBACK_DATA = {
  user: {
    public_repos: 14,
    followers: 22,
    following: 28,
    login: "Princejha10",
    name: "Prince Jha",
  },
  repos: [
    {
      name: "FinSense",
      description: "Automated expense monitoring parsing SMS context tokens securely on-device.",
      stargazers_count: 4,
      forks_count: 1,
      language: "Dart",
      html_url: "https://github.com/Princejha10/FinSense",
    },
    {
      name: "AAI-Log-Audit-Pipeline",
      description: "Database event aggregator and reporting daemon detecting anomaly configurations.",
      stargazers_count: 2,
      forks_count: 0,
      language: "Python",
      html_url: "https://github.com/Princejha10",
    },
    {
      name: "Portfolio-v2",
      description: "Redesigned creative portfolio built with Next.js, Framer Motion, and GSAP.",
      stargazers_count: 1,
      forks_count: 0,
      language: "JavaScript",
      html_url: "https://github.com/Princejha10",
    }
  ],
  languages: [
    { name: "Dart & Flutter", pct: 55, color: "bg-cyan-500" },
    { name: "Python", pct: 35, color: "bg-blue-500" },
    { name: "JavaScript / Web", pct: 10, color: "bg-yellow-500" }
  ]
};

export default function GithubActivity() {
  const [data, setData] = useState(FALLBACK_DATA);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function fetchGithubStats() {
      try {
        const username = "Princejha10";
        // Fetch User profile
        const userRes = await fetch(`https://api.github.com/users/${username}`);
        if (!userRes.ok) throw new Error("User request rate limit/not found");
        const userData = await userRes.json();

        // Fetch user public repos
        const reposRes = await fetch(`https://api.github.com/users/${username}/repos?sort=updated&per_page=6`);
        if (!reposRes.ok) throw new Error("Repos request rate limit/not found");
        const reposData = await reposRes.json();

        // Map languages count
        const langMap = {};
        let totalCount = 0;
        reposData.forEach(r => {
          if (r.language) {
            langMap[r.language] = (langMap[r.language] || 0) + 1;
            totalCount++;
          }
        });

        const sortedLanguages = Object.entries(langMap)
          .map(([name, count]) => {
            const pct = Math.round((count / totalCount) * 100);
            let color = "bg-zinc-500";
            if (name === "Dart") color = "bg-cyan-500";
            if (name === "Python") color = "bg-blue-500";
            if (name === "JavaScript" || name === "TypeScript") color = "bg-yellow-500";
            return { name, pct, color };
          })
          .sort((a, b) => b.pct - a.pct);

        setData({
          user: {
            public_repos: userData.public_repos,
            followers: userData.followers,
            following: userData.following,
            login: userData.login,
            name: userData.name || userData.login,
          },
          repos: reposData.slice(0, 3).map(r => ({
            name: r.name,
            description: r.description || "No description provided.",
            stargazers_count: r.stargazers_count,
            forks_count: r.forks_count,
            language: r.language || "Unknown",
            html_url: r.html_url,
          })),
          languages: sortedLanguages.length > 0 ? sortedLanguages : FALLBACK_DATA.languages
        });
      } catch (err) {
        console.warn("GitHub API rate limit or error, falling back to cached profile metrics:", err.message);
        // Fall back to clean default metrics
        setData(FALLBACK_DATA);
      } finally {
        setIsLoading(false);
      }
    }

    fetchGithubStats();
  }, []);

  // Contribution graph columns logic (mock layout conforming to genuine grid look)
  const contributionGrid = [];
  const weeks = 24; // Width matching layout
  const days = 7;
  for (let i = 0; i < weeks * days; i++) {
    // Generate organic-looking contribution densities
    const val = Math.random();
    let level = "bg-zinc-900/40";
    if (val > 0.85) level = "bg-[#FF2B2B]/20";
    else if (val > 0.7) level = "bg-[#FF2B2B]/45";
    else if (val > 0.55) level = "bg-[#FF2B2B]/75";
    else if (val > 0.4) level = "bg-[#FF2B2B]";
    contributionGrid.push(level);
  }

  return (
    <section id="github" className="py-24 px-6 md:px-12 max-w-5xl mx-auto w-full relative border-t border-white/5 bg-[#050505]">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-16">
        <div className="flex flex-col items-start gap-4 text-left">
          <div className="font-mono text-xs uppercase tracking-widest text-[#FF2B2B] flex items-center gap-2">
            <Github className="w-4 h-4 text-[#FF2B2B]" />
            <span>GitHub Sync</span>
          </div>
          <h2 className="font-heading text-2xl md:text-3xl font-bold tracking-tight text-white uppercase">
            Active Statistics
          </h2>
        </div>

        {/* Sync Status Badge */}
        <div className="flex items-center gap-2 px-3 py-1 rounded bg-white/5 border border-white/5 text-[9px] font-mono text-[#A3A3A3] self-start md:self-end">
          <span className="w-1.5 h-1.5 rounded-full bg-[#10B981] animate-ping" />
          <span>CONNECTED • API LIVE</span>
        </div>
      </div>

      {/* Main Github Widgets Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Profile Card & Info */}
        <div className="bg-[#111111] border border-white/5 rounded-2xl p-6 flex flex-col justify-between text-left">
          <div>
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 rounded-full bg-[#FF2B2B] flex items-center justify-center text-white font-bold text-lg uppercase shadow-[0_0_15px_rgba(255,43,43,0.15)]">
                P
              </div>
              <div>
                <h4 className="font-heading text-base font-bold text-white uppercase tracking-tight">
                  {data.user.name}
                </h4>
                <a
                  href={`https://github.com/${data.user.login}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="font-mono text-[10px] text-[#A3A3A3] hover:text-[#FF2B2B] transition-colors"
                >
                  @{data.user.login}
                </a>
              </div>
            </div>

            {/* Profile Statistics metrics */}
            <div className="space-y-4">
              <div className="flex items-center justify-between border-b border-white/5 pb-2">
                <span className="font-sans text-xs text-[#A3A3A3]">Followers</span>
                <span className="font-mono text-sm font-bold text-white flex items-center gap-1">
                  <Users className="w-3.5 h-3.5 text-[#FF2B2B]" />
                  {data.user.followers}
                </span>
              </div>
              <div className="flex items-center justify-between border-b border-white/5 pb-2">
                <span className="font-sans text-xs text-[#A3A3A3]">Following</span>
                <span className="font-mono text-sm font-bold text-white">
                  {data.user.following}
                </span>
              </div>
              <div className="flex items-center justify-between border-b border-white/5 pb-2">
                <span className="font-sans text-xs text-[#A3A3A3]">Public Repos</span>
                <span className="font-mono text-sm font-bold text-white flex items-center gap-1">
                  <BookOpen className="w-3.5 h-3.5 text-[#FF2B2B]" />
                  {data.user.public_repos}
                </span>
              </div>
            </div>
          </div>

          <a
            href={`https://github.com/${data.user.login}`}
            target="_blank"
            rel="noopener noreferrer"
            className="magnetic-btn w-full mt-6 py-2.5 rounded-xl bg-white/5 hover:bg-white/10 text-white font-heading text-xs font-semibold uppercase tracking-wider text-center border border-white/5 transition-all"
          >
            Visit Profile
          </a>
        </div>

        {/* Pinned / Recent Repos List */}
        <div className="bg-[#111111] border border-white/5 rounded-2xl p-6 flex flex-col justify-between md:col-span-2 text-left">
          <div className="space-y-4">
            <span className="font-mono text-[9px] text-[#A3A3A3] uppercase tracking-wider block">
              Recent Repositories
            </span>
            <div className="space-y-4">
              {data.repos.map((repo) => (
                <a
                  key={repo.name}
                  href={repo.html_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="block p-4 rounded-xl border border-white/5 bg-[#0A0A0A] hover:border-[#FF2B2B]/20 transition-all group"
                >
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="font-heading text-sm font-bold text-white uppercase tracking-tight group-hover:text-[#FF2B2B] transition-colors">
                      {repo.name}
                    </span>
                    <div className="flex items-center gap-3 font-mono text-[10px] text-[#A3A3A3]">
                      <span className="flex items-center gap-1">
                        <Star className="w-3.5 h-3.5 text-amber-500" />
                        {repo.stargazers_count}
                      </span>
                      <span className="flex items-center gap-1">
                        <GitFork className="w-3.5 h-3.5 text-zinc-500" />
                        {repo.forks_count}
                      </span>
                    </div>
                  </div>
                  <p className="font-sans text-[11px] text-[#A3A3A3] line-clamp-1">
                    {repo.description}
                  </p>
                  <div className="flex items-center gap-2 mt-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-cyan-500" />
                    <span className="font-mono text-[8px] uppercase text-[#A3A3A3]">{repo.language}</span>
                  </div>
                </a>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Contribution Activity Graph block */}
      <div className="bg-[#111111] border border-white/5 rounded-2xl p-6 mt-6 text-left">
        <span className="font-mono text-[9px] text-[#A3A3A3] uppercase tracking-wider block mb-4">
          Contribution Density Flow (Mock representation)
        </span>
        <div className="w-full overflow-x-auto scrollbar-none">
          <div className="grid grid-flow-col grid-rows-7 gap-1.5 min-w-[620px] pb-2">
            {contributionGrid.map((level, idx) => (
              <div key={idx} className={`w-3.5 h-3.5 rounded-sm ${level}`} />
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
