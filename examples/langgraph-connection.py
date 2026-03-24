#!/usr/bin/env python3
"""
Point LangGraph + LangChain at an OpenAI-compatible server (e.g. vLLM on the Spark head).

  pip install -r examples/requirements-langgraph.txt
  export VLLM_BASE_URL=http://10.0.0.1:8000/v1
  export VLLM_MODEL=Qwen/Qwen2.5-7B-Instruct   # or whatever /v1/models reports

vLLM exposes OpenAI-compatible routes; api_key is often unused—use a placeholder.
"""

from __future__ import annotations

import os
from typing import Annotated, TypedDict

from langchain_core.messages import HumanMessage
from langchain_openai import ChatOpenAI
from langgraph.graph import END, START, StateGraph
from langgraph.graph.message import add_messages


class State(TypedDict):
    messages: Annotated[list, add_messages]


def main() -> None:
    base_url = os.environ.get("VLLM_BASE_URL", "http://127.0.0.1:8000/v1").rstrip("/")
    model = os.environ.get("VLLM_MODEL", "Qwen/Qwen2.5-7B-Instruct")
    api_key = os.environ.get("OPENAI_API_KEY", "EMPTY")

    llm = ChatOpenAI(
        base_url=base_url,
        api_key=api_key,
        model=model,
        temperature=0.2,
    )

    def chat_node(state: State) -> dict:
        reply = llm.invoke(state["messages"])
        return {"messages": [reply]}

    graph = StateGraph(State)
    graph.add_node("chat", chat_node)
    graph.add_edge(START, "chat")
    graph.add_edge("chat", END)
    app = graph.compile()

    out = app.invoke(
        {
            "messages": [
                HumanMessage(
                    content="Reply in one sentence: what is tensor parallelism?"
                ),
            ]
        }
    )
    print(out["messages"][-1].content)


if __name__ == "__main__":
    main()
