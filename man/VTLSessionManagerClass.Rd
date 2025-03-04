% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/VTLSessionManager.R
\name{VTLSessionManagerClass}
\alias{VTLSessionManagerClass}
\title{Manage VTL sessions}
\description{
R6 class to create, find and destroy VTL sessions
}
\details{
This R6 class is used to create, find and destroy VTL sessions
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-VTLSessionManager-new}{\code{VTLSessionManagerClass$new()}}
\item \href{#method-VTLSessionManager-finalize}{\code{VTLSessionManagerClass$finalize()}}
\item \href{#method-VTLSessionManager-list}{\code{VTLSessionManagerClass$list()}}
\item \href{#method-VTLSessionManager-clear}{\code{VTLSessionManagerClass$clear()}}
\item \href{#method-VTLSessionManager-kill}{\code{VTLSessionManagerClass$kill()}}
\item \href{#method-VTLSessionManager-getOrCreate}{\code{VTLSessionManagerClass$getOrCreate()}}
\item \href{#method-VTLSessionManager-reload}{\code{VTLSessionManagerClass$reload()}}
\item \href{#method-VTLSessionManager-clone}{\code{VTLSessionManagerClass$clone()}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-VTLSessionManager-new"></a>}}
\if{latex}{\out{\hypertarget{method-VTLSessionManager-new}{}}}
\subsection{Method \code{new()}}{
Creates a new manager instance.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{VTLSessionManagerClass$new()}\if{html}{\out{</div>}}
}

\subsection{Details}{
This method should not be called by the application.
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-VTLSessionManager-finalize"></a>}}
\if{latex}{\out{\hypertarget{method-VTLSessionManager-finalize}{}}}
\subsection{Method \code{finalize()}}{
Finalization
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{VTLSessionManagerClass$finalize()}\if{html}{\out{</div>}}
}

\subsection{Details}{
Clears any managed VTL session when this manager is discarded by the garbage collector.
This method should not be called by the application.
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-VTLSessionManager-list"></a>}}
\if{latex}{\out{\hypertarget{method-VTLSessionManager-list}{}}}
\subsection{Method \code{list()}}{
List all active named VTL sessions.
If an active SDMX metadata repository is active, also load Transformation schemes from it
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{VTLSessionManagerClass$list()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-VTLSessionManager-clear"></a>}}
\if{latex}{\out{\hypertarget{method-VTLSessionManager-clear}{}}}
\subsection{Method \code{clear()}}{
All active VTL sessions are killed and a new VTL session named 'test' is created.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{VTLSessionManagerClass$clear()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-VTLSessionManager-kill"></a>}}
\if{latex}{\out{\hypertarget{method-VTLSessionManager-kill}{}}}
\subsection{Method \code{kill()}}{
Silently terminates the named active VTL session if it exists.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{VTLSessionManagerClass$kill(sessionID)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{sessionID}}{The name of the session to kill}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-VTLSessionManager-getOrCreate"></a>}}
\if{latex}{\out{\hypertarget{method-VTLSessionManager-getOrCreate}{}}}
\subsection{Method \code{getOrCreate()}}{
If the named VTL session exists, return it, otherwise create a new VTL session with the given name and possibly code.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{VTLSessionManagerClass$getOrCreate(sessionID)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{sessionID}}{The session to retrieve or create
The name of the session to create}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-VTLSessionManager-reload"></a>}}
\if{latex}{\out{\hypertarget{method-VTLSessionManager-reload}{}}}
\subsection{Method \code{reload()}}{
Reload the configuration of the current session, reloading the repository and the environments.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{VTLSessionManagerClass$reload()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-VTLSessionManager-clone"></a>}}
\if{latex}{\out{\hypertarget{method-VTLSessionManager-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{VTLSessionManagerClass$clone(deep = FALSE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{deep}}{Whether to make a deep clone.}
}
\if{html}{\out{</div>}}
}
}
}
