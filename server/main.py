import asyncio
import json
from aiohttp import web
from aiortc import RTCPeerConnection, RTCSessionDescription

pc = RTCPeerConnection()
