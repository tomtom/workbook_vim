:power
import tools.nsc.interpreter.Completion.Candidates

def workbookComplete(text: String): Unit = {
  val Candidates(_, cs) = completion.completer.complete(text, text.length)
  cs.foreach { println }
}

